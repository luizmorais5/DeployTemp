public without sharing class ATMCaseSLAManager {

	private static final Map<Id, RecordType> CASE_RECORDTYPEMAP = new Map<Id, RecordType>(
		[SELECT Id, DeveloperName FROM RecordType WHERE SObjectType = 'Case']
	);

	//Task 135159 - Scenario 1: Hub Selection
    public static void populateATMHubLocation(List<Case> caseList) {
    
        List<Case> casesToProcess = filterEligibleCases(caseList);
        if (casesToProcess == null || casesToProcess.isEmpty()) {
            return;
        }
    
        Map<Id, Merchant_Location__c> merchantLocationMap = fetchMerchantLocations(casesToProcess);
        if (merchantLocationMap == null || merchantLocationMap.isEmpty()) {
            return;
        }
    
        Map<String, String> parishToHubMap = buildParishToHubMap();
        if (parishToHubMap == null || parishToHubMap.isEmpty()) {
            return;
        }
    
        Map<String, ServiceTerritory> serviceTerritoryByNameMap = buildServiceTerritoryByNameMap();
        if (serviceTerritoryByNameMap == null || serviceTerritoryByNameMap.isEmpty()) {
            return;
        }
    
        List<Merchant_Location__c> merchantLocationsToUpdate = new List<Merchant_Location__c>();
        for (Case c : casesToProcess) {
            if (c.Merchant_Location_Id__c == null) {
                continue;
            }
    
            Merchant_Location__c merchantLocation = merchantLocationMap.get(c.Merchant_Location_Id__c);
            if (merchantLocation != null && 
                String.isNotBlank(merchantLocation.Parish_Province_State_list__c) &&
                String.isBlank(merchantLocation.Service_Hub_Id__c)) 
            {
                String parishRaw = merchantLocation.Parish_Province_State_list__c;
                String parishKey = parishRaw != null ? parishRaw.trim().toLowerCase() : null;
                if (String.isNotBlank(parishKey) && parishToHubMap.containsKey(parishKey)) {
                    String hubName = parishToHubMap.get(parishKey);
                    ServiceTerritory serviceTerritory = serviceTerritoryByNameMap.get(hubName);
                    
                    if (serviceTerritory != null && serviceTerritory.Id != null) {
                        merchantLocationsToUpdate.add(new Merchant_Location__c(
                            Id = merchantLocation.Id,
                            Service_Hub_Id__c = serviceTerritory.Id
                        ));
                    }
                }
            }
        }
    
        if (!merchantLocationsToUpdate.isEmpty()) {
            update merchantLocationsToUpdate;
        }
    }    

    private static List<Case> filterEligibleCases(List<Case> cases) {
        List<Case> filtered = new List<Case>();
        for (Case c : cases) {
            if (c.RecordTypeId != null && 
				CASE_RECORDTYPEMAP.get(c.RecordTypeId).DeveloperName == 'ATM' &&
                c.Merchant_Location_Id__c != null) 
            {
                filtered.add(c);
            }
        }
        return filtered;
    }

    private static Map<Id, Merchant_Location__c> fetchMerchantLocations(List<Case> cases) {
        Set<Id> merchantLocationIds = new Set<Id>();
        for (Case c : cases) {
            merchantLocationIds.add(c.Merchant_Location_Id__c);
        }
        
        return new Map<Id, Merchant_Location__c>(
            [SELECT Id, Parish_Province_State_list__c, Service_Hub_Id__c, KilometerRadius__c
             FROM Merchant_Location__c 
             WHERE Id IN :merchantLocationIds]
        );
    }

    private static Map<String, ServiceTerritory> buildServiceTerritoryByNameMap() {
        Map<String, ServiceTerritory> serviceTerritoryByNameMap = new Map<String, ServiceTerritory>();
        for (ServiceTerritory territory : [
            SELECT Id, Name
            FROM ServiceTerritory
            WHERE Name Like 'ATM%'
        ]) {
            serviceTerritoryByNameMap.put(territory.Name, territory);
        }

        return serviceTerritoryByNameMap;
    }

    private static Map<String, String> buildParishToHubMap() {
        Map<String, String> parishToHub = new Map<String, String>();
        for (ATM_HubParishes__mdt hubMapping : [
            SELECT Hub__c, Parishes__c FROM ATM_HubParishes__mdt
        ]) {
            if (String.isNotBlank(hubMapping.Parishes__c)) {
                for (String parish : hubMapping.Parishes__c.split(',')) {
                    parishToHub.put(parish.trim().toLowerCase(), hubMapping.Hub__c);
                }
            }
        }
        return parishToHub;
    }

	//Task 135159 Scenario 2: Kilometre Radius Field Population 
	public static void calculateKilometerRadius(List<Case> incomingCases, Map<Id, Case> previousCasesMap) {
		Set<Id> merchantLocationIds = new Set<Id>();
	
		for (Case c : incomingCases) {
				merchantLocationIds.add(c.Merchant_Location_Id__c);
		}
	
		Map<Id, Merchant_Location__c> merchantLocationMap = new Map<Id, Merchant_Location__c>(
			[SELECT Id, KilometerRadius__c FROM Merchant_Location__c WHERE Id IN :merchantLocationIds]
		);
	
		List<Id> locationsToProcess = new List<Id>();
        List<Id> casesToProcess = new List<Id>();
		for (Case c : incomingCases) {
			if (shouldCalculateDistance(c, merchantLocationMap)) {
				locationsToProcess.add(c.Merchant_Location_Id__c);
                casesToProcess.add(c.Id);
			}
		}
	
		if (!locationsToProcess.isEmpty()) {
			DistanceFutureHelper.processLocationsAsync(locationsToProcess,casesToProcess);
		}
	}

	private static Boolean shouldCalculateDistance(Case c, Map<Id, Merchant_Location__c> merchantLocationMap) {
        //verificar formula e flah
		if (c.Merchant_Location_Id__c != null &&
			CASE_RECORDTYPEMAP.containsKey(c.RecordTypeId) &&
			CASE_RECORDTYPEMAP.get(c.RecordTypeId).DeveloperName == 'ATM') 
		{
			Merchant_Location__c merchantLocation = merchantLocationMap.get(c.Merchant_Location_Id__c);
			return merchantLocation != null && merchantLocation.KilometerRadius__c == null;
		}
		return false;
	}

    
    // Tasks:

    public static void processATMSlaCases(List<Case> newCases, Map<Id, Case> oldCases) {
        List<Case> casesToProcess = new List<Case>();

        for (Case newCase : newCases) {
            RecordType recordType = CASE_RECORDTYPEMAP.get(newCase.RecordTypeId);
            if (recordType != null && recordType.DeveloperName == 'ATM') {
                if (isSlaProcessChanged(newCase, oldCases)) {
                    casesToProcess.add(newCase);
                }
            }
        }
        processSlaForCases(casesToProcess);
    }

    private static Boolean isSlaProcessChanged(Case newCase, Map<Id, Case> oldCases) {
        Case oldCase = oldCases != null ? oldCases.get(newCase.Id) : new Case();
        
        return (newCase.Severity__c != null && (oldCase == null || newCase.Severity__c != oldCase.Severity__c)) ||
               (newCase.Charge_Type_list__c != null && (oldCase == null || newCase.Charge_Type_list__c != oldCase.Charge_Type_list__c)) ||
               (newCase.Service_Type_list__c != null && (oldCase == null || newCase.Service_Type_list__c != oldCase.Service_Type_list__c)) ||
               (newCase.KmRadiusCalculated__c == true && (oldCase == null || oldCase.KmRadiusCalculated__c != true));
    }
    

    private static void processSlaForCases(List<Case> casesToProcess) {
        if (casesToProcess.isEmpty()) {
            System.debug('No cases to process for ATM SLA.');
            return;
        }

        List<ATM_SLAEntitlementMapping__mdt> metadataRecords = [
            SELECT Label, ChargeType__c, Severity__c, ServiceType__c, Company__c, EntitlementProcess__c, KilometreRadiusStart__c, KilometreRadiusEnd__c
            FROM ATM_SLAEntitlementMapping__mdt
            WHERE IsActive__c = TRUE
        ];

        Map<String, List<ATM_SLAEntitlementMapping__mdt>> metadataMap = new Map<String, List<ATM_SLAEntitlementMapping__mdt>>();

        for (ATM_SLAEntitlementMapping__mdt record : metadataRecords) {
            String key = generateMetadataKey(record);
            if (!metadataMap.containsKey(key)) {
                metadataMap.put(key, new List<ATM_SLAEntitlementMapping__mdt>());
            }
            metadataMap.get(key).add(record);
        }

        Map<Id, Account> accountByIdMap = fetchAccounts(casesToProcess);

        Map<String, Entitlement> entitlementMap = new Map<String, Entitlement>();
        for (Entitlement ent : [SELECT Id, Name FROM Entitlement WHERE Status = 'Active']) {
            entitlementMap.put(ent.Name, ent);
        }

        Map<Id, Merchant_Location__c> merchantLocationMap = fetchMerchantLocations(casesToProcess);

        List<Case> casesToUpdate = new List<Case>();

        for (Case caseToProcess : casesToProcess) {
            Account account = accountByIdMap.get(caseToProcess.AccountId);
            if (account == null) {
                System.debug('Skipping case without related account: ' + caseToProcess.Id);
                continue;
            }

            String key = generateMetadataKeyForCase(caseToProcess, account);
            List<ATM_SLAEntitlementMapping__mdt> entitlementMappings = metadataMap.get(key);

            if (entitlementMappings == null) {
                caseToProcess.EntitlementId = getDefaultEntitlement(account.Name).Id;
                casesToUpdate.add(caseToProcess);                
                
                System.debug('No entitlement mappings found for key: ' + key);
                continue;
            }

            Merchant_Location__c merchantLocation = merchantLocationMap.get(caseToProcess.Merchant_Location_Id__c);
            if (merchantLocation == null) {
                System.debug('No merchant location found for case: ' + caseToProcess.Id);
                continue;
            }

            Boolean entitlementAssigned = false;
            for (ATM_SLAEntitlementMapping__mdt entitlementMapping : entitlementMappings) {
                if (!entitlementMapping.ServiceType__c.contains(caseToProcess.Service_Type_list__c)) {
                    continue;
                }

                if (merchantLocation.KilometerRadius__c != null &&
                    merchantLocation.KilometerRadius__c >= entitlementMapping.KilometreRadiusStart__c &&
                    merchantLocation.KilometerRadius__c <= entitlementMapping.KilometreRadiusEnd__c) {

                    Entitlement entitlement = entitlementMap.get(entitlementMapping.EntitlementProcess__c);
                    if (entitlement != null) {
                        caseToProcess.EntitlementId = entitlement.Id;
                        casesToUpdate.add(caseToProcess);
                        entitlementAssigned = true;
                        System.debug('Entitlement assigned for case: ' + caseToProcess.Id + ' using entitlement: ' + entitlement.Name);
                        break;
                    } else {
                        System.debug('Entitlement process not found in entitlement map for: ' + entitlementMapping.EntitlementProcess__c);
                    }
                }
            }

            if (!entitlementAssigned) {
                caseToProcess.EntitlementId = getDefaultEntitlement(account.Name).Id;
                casesToUpdate.add(caseToProcess);
                System.debug('Default entitlement assigned for case:' + caseToProcess.Id);
            }
        }

        if (!casesToUpdate.isEmpty()) {
            System.debug('Updated ' + casesToUpdate.size() + ' cases with entitlement.');
        } else {
            System.debug('No cases required update for entitlement.');
        }
    }

    private static String generateMetadataKey(ATM_SLAEntitlementMapping__mdt record) {
        return record.ChargeType__c + '-' + record.Severity__c + '-' + record.Company__c;
    }

    private static String generateMetadataKeyForCase(Case caseToProcess, Account account) {
        return caseToProcess.Charge_Type_list__c + '-' + caseToProcess.Severity__c + '-' + account.Name;
    }

    private static Map<Id, Account> fetchAccounts(List<Case> cases) {
        Set<Id> accountIds = new Set<Id>();
        for (Case c : cases) {
            if (c.AccountId != null) {
                accountIds.add(c.AccountId);
            }
        }

        return new Map<Id, Account>(
            [SELECT Id, Name FROM Account WHERE Id IN :accountIds]
        );
    }


    private static Entitlement getDefaultEntitlement(String bankName) {
        String entitlementName = 'ATM ' + bankName;
        List<Entitlement> entitlements = [
            SELECT Id FROM Entitlement
            WHERE Name = :entitlementName AND Account.Name = :bankName
            LIMIT 1
        ];
        if (!entitlements.isEmpty()) {
            return entitlements[0];
        } else {
            System.debug('No default entitlement found for bank: ' + bankName);
            return null;
        }
    }
}