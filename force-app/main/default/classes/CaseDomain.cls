/**
 *  Name  :  CaseDomain
 *  Author:  Thinqloud Solutions
 *  Date  :  Jan 11, 2021
 *  Purpose : Case related operations are done here. This class is mainly performing
 *           Operations on cases for different tickets in Standard Support Process, Enhancement Process
 *           And Hotfix Process.
 **/
public class CaseDomain {
	//declaring variables which would be needed to all below functions. ----------------------
	public static Map<String, Id> caseRecordTypes = CaseSelector.getRecordTypeNames('Case');
	public static Map<String, Group> groupMap = CaseSelector.getAvailableQueueGroup();
	public static Map<String, List<Id>> groupMemMap = CaseSelector.getGroupsMembersMap();
	public static Map<String, EmailTemplate> templateMap = CaseSelector.getemailTemplatesMap();
	public static Map<String, List<User>> queueUsersMap = CaseSelector.getQueueUsersInfo();
	public static List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
	public static List<Opportunity> insertNewWOList = new List<Opportunity>();
	public static List<User> userList = new List<User>();
	public static Map<Id, Lead> caseVsLead = new Map<Id, Lead>();
	public static Map<Id, Case> caseIdVsCaseRecord = new Map<Id, Case>();
	public static List<Id> caseIdsToCloseMilestones = new List<Id>();
	public static List<string> milestonesNamesToClose = new List<String>();
	public static id loggedInUserId = UserInfo.getUserId();
	public static User current_user = CaseSelector.getUserDetail(loggedInUserId);

	/**
	 * @description assign either premium or regular entitlements
	 * @author Remario Richards | 12-03-2023
	 * @param records
	 * @param merchantAccounts
	 * @param mappedEntitlements
	 * @return Boolean
	 **/
	public static Boolean assignAllEntitlementsV2( List<Case> records, Map<Id, Account> merchantAccounts,Map<String, Id> mappedEntitlements,Map<Id, Merchant_Location__c> merchantLocationMap) {
		
		Set<Id> alreadyAssignedCases = new Set<Id>();

		EntitlementSettingWrapper settingwrapper = new EntitlementSettingWrapper();

		for (Case caseRecord : records) {

			if (caseRecord.Status != 'New') {
				continue;
			}

			if (alreadyAssignedCases.contains(caseRecord.Id)) {
				break;
			}
			//Get a list of EntitlementSetting Records for the Bank
			List<EntitlementSettingWrapper.Record> wrappedSettings = settingwrapper.mappedSettings
				?.get(merchantAccounts.get(caseRecord?.AccountId)?.Name);

				System.debug('# wrappedSettings ' + wrappedSettings);

				if (wrappedSettings == null) {
					continue;
				}

			for (EntitlementSettingWrapper.Record wrappedSettingRecord : wrappedSettings) {

				//: check for sevice type
				Boolean serviceTypeIncluded = wrappedSettingRecord.serviceTypes.contains(caseRecord.Service_Type_list__c);

				// check for sla type
				Boolean slaTimeIncluded = caseRecord.SLA_Expected_Time__c == wrappedSettingRecord.slaType;

				//check for kilometer distance
				Boolean distanceIncluded = kilometerDistanceCheck(caseRecord, merchantLocationMap, wrappedSettingRecord);

				//check for record types
				Boolean recordTypeIncluded = caseRecord.RecordTypeid == caseRecordTypes.get(wrappedSettingRecord.recordTypeName);
				
				System.debug('# serviceTypeIncluded ' + serviceTypeIncluded);
				System.debug('# caseRecord.Service_Type_list__c ' + caseRecord.Service_Type_list__c);
				System.debug('# recordTypeIncluded ' + recordTypeIncluded);
				System.debug('# caseRecord.SLA_Expected_Time__c ' + caseRecord.SLA_Expected_Time__c);
				System.debug('# slaTimeIncluded ' + slaTimeIncluded);
				System.debug('# distanceIncluded ' + distanceIncluded);
					
				if (serviceTypeIncluded && recordTypeIncluded && slaTimeIncluded && distanceIncluded) {

						caseRecord.EntitlementId = mappedEntitlements.get(wrappedSettingRecord.entitlementName.toLowerCase());
						caseRecord.SLA_Status_list__c = 'In Progress';
						alreadyAssignedCases.add(caseRecord.Id);
						break;
				}
			}
		}
		return false;
	}
	/**
	 * @description check parishes within or outside kilometer radius
	 * @author Remario Richards | 12-03-2023
	 * @param caseRecord
	 * @param merchantAccount
	 * @param wrappedSettingRecord
	 * @return Boolean
	public static Boolean kilometerDistanceCheck(
		Case caseRecord,
		Map<Id, Account> merchantAccounts,
		EntitlementSettingWrapper.Record wrappedSettingRecord
	) {
		if (wrappedSettingRecord.applyDistanceCheck == false)
			return true; //distance check is not required by the bank
		Account merchantAccount = merchantAccounts.get(
			caseRecord?.Merchant_Name_ID__c
		);
		if (wrappedSettingRecord.radiusDistanceType == 'Within') {
			return wrappedSettingRecord.parishes != null && merchantAccount?.Parish__c != null &&
				wrappedSettingRecord.parishes.contains(merchantAccount.Parish__c);
		}
		return wrappedSettingRecord.parishes != null && merchantAccount?.Parish__c != null &&
			!wrappedSettingRecord.parishes.contains(merchantAccount.Parish__c);
	}
		**/
		public static Boolean kilometerDistanceCheck(Case caseRecord,Map<Id, Merchant_Location__c> merchantLocationMap,EntitlementSettingWrapper.Record wrappedSettingRecord) {
			Boolean result = false; 
					
			Merchant_Location__c  merchantLocation = merchantLocationMap.get(caseRecord?.Merchant_Location_Id__c);

			if(merchantLocation == null){
				return false;
			}

			String country = !String.isBlank(merchantLocation.Country_list__c) ? merchantLocation.Country_list__c : '';
			System.debug('## merchantLocation Country ' + country);
			String parish = !String.isBlank(merchantLocation.Parish_Province_State_list__c) ? merchantLocation.Parish_Province_State_list__c : ''; 
			System.debug('## merchantLocation parish ' + parish);

			System.debug('## wrappedSettingRecord.country ' + wrappedSettingRecord.country);
			System.debug('## wrappedSettingRecord.parishes ' + wrappedSettingRecord.parishes);


			if (wrappedSettingRecord.radiusDistanceType == 'Within') {
				System.debug('## Within ');

        //distance check is not required by the bank
			  if (wrappedSettingRecord.applyDistanceCheck == false && String.isBlank(parish)){
					if(wrappedSettingRecord.country == country){
						result = true;
					}			  
        }
        else {
          if(wrappedSettingRecord.parishes != null && wrappedSettingRecord.parishes.contains(parish) && wrappedSettingRecord.country == country){
            result = true;
          } 
        }
			}
			
			if (wrappedSettingRecord.radiusDistanceType == 'Outside') {
				System.debug('## Outside ');

			  if (wrappedSettingRecord.applyDistanceCheck == false && String.isBlank(parish)){
					if(wrappedSettingRecord.country == country){
						result = true;
					}
				}
				else {
					if(wrappedSettingRecord.parishes != null && !wrappedSettingRecord.parishes.contains(parish) && wrappedSettingRecord.country == country){
						result = true;
					}
				}
			}

			System.debug('## result ' + result);
			return result;
		}
		
	public class RegularEntitlementProcessMap {
		public Account merchantAccount;
		public String slaExpectedTime;
		public List<String> serviceTypes;
		public String radiusDistance;
		public String recordTypeNameId;
		public Id entitlementId;
		/**
		 * @description check if service type is matched
		 * @author Remario Richards | 09-03-2023
		 * @param serviceType
		 * @return Boolean
		 **/
		public Boolean isServiceTypeIncluded(String serviceType) {
			for (String record : serviceTypes) {
				if (record == serviceType) {
					return true;
				}
			}
			return false;
		}
	}
	/**
	 * @description close premium and regular milestones
	 * @author Remario Richards | 09-05-2023
	 * @param cases
	 * @param oldMap
	 **/
	public static void regularAndPremiumMilestoneCompletionCriteria(List<Case> cases, Map<Id, Case> oldMap) {
		Id posCaseRecordTypeId = caseRecordTypes.get('POS');
		Set<string> milestonesNamesToClose = new Set<String>();
		Set<Id> caseIdsToCloseMilestones = new Set<Id>();

		List<CaseMilestone> milestones = CaseSelector.getActiveMilestonesForCases(
			new Set<String>{
				'Dispatcher Vets and Acknowledge Case and Create Work Order'
			},
			oldMap.keySet()
		);
		
		for (Case record : cases) {
			Case oldRecord = oldMap.get(record.Id);
			caseIdsToCloseMilestones.add(record.Id);

			if (record.RecordTypeId == posCaseRecordTypeId && oldRecord.IsClosed == false && record.IsClosed) {
				milestonesNamesToClose.add('Programming, Service Appointment Creation & Service Appointment Completion');
				milestonesNamesToClose.add('Service Appointment Creation & Service Appointment Completion');
				milestonesNamesToClose.add('SLA Total Hours');
			}

			//scenario 1
			if (
				record.Status == 'Acknowledged' &&
				record.NoWOCreated__c == false &&
				record.RecordTypeId == posCaseRecordTypeId &&
				record.Submitted_to_Programming__c == true &&
				record.IsClosed ==  false
			) {
				milestonesNamesToClose.add(
					'Dispatcher Vet, Acknowledge Case,Create Work Order n Product Request Submission'
				);
			}
			//scenario 2
			if (
				record.RecordTypeId == posCaseRecordTypeId &&
				record.Transferred_to_Senior_POS_Logistics__c == true &&
				record.IsClosed ==  false
			) {
				milestonesNamesToClose.add(
					'Device Programming and transfer to Senior POS Officer/Logistics'
				);
			}
			//scenario 3
			if (
				record.RecordTypeId == posCaseRecordTypeId &&
				record.Transferred_to_Lead_Contractor_MSO__c == true &&
				record.IsClosed ==  false
			) {
				milestonesNamesToClose.add(
					'Device transfer to Lead Contractor MSO at out-of-town hub'
				);
			}
			//scenario 4
			if (
				record.RecordTypeId == posCaseRecordTypeId &&
				record.Service_Appointment_Created__c == true &&
				record.IsClosed ==  false
			) {
				milestonesNamesToClose.add('Service Appointment creation');
			}
			//scenario 5
			if (
				record.RecordTypeId == posCaseRecordTypeId &&
				oldRecord.IsClosed == false &&
				record.IsClosed
			) {
				milestonesNamesToClose.add(
					'Installation & Service Appointment & Work Order Completion'
				);
			}
			//scenario 6
			if (
				record.RecordTypeId == posCaseRecordTypeId &&
				!milestones.isEmpty() &&
				record.Status == 'Acknowledged' &&
				record.NoWOCreated__c == false
			) {
				milestonesNamesToClose.add(
					'Dispatcher Vets and Acknowledge Case and Create Work Order'
				);
			}
						//scenario 7
		if (
			record.RecordTypeId == posCaseRecordTypeId &&
			oldRecord.IsClosed == false &&
			record.IsClosed
		) {
			milestonesNamesToClose.add(
				'Service Appointment & Work Order Completion'
			);
		}
		}
		CaseSelector.completeMilestone(
			new List<Id>(caseIdsToCloseMilestones),
			new List<String>(milestonesNamesToClose),
			DateTime.now()
		);
	}

	/**
	 * @description unpause the stopped case recorsd
	 * @author Remario Richards | 09-05-2023
	 * @param records
	 **/
	public static List<Case> automaticUnpausingOfSLA(
		List<Case> records,
		Map<Id, Case> oldCases
	) {
		General_Entitlement_Config__mdt config = getGeneralConfig('General');
		Set<String> values = new Set<String>(config.Unpause_Reasons__c.split('\n'));
		List<Case> stoppedCases = new List<Case>();
		for (Case record : records) {
			Case oldRecord = oldCases.get(record.id);
			for (String key : values) {
				key = key.trim();
				if (
					record.Sub_Status_FS__c != null &&
					record.Sub_Status_FS__c == key &&
					record.Sub_Status_FS__c != oldRecord.Sub_Status_FS__c &&
					record.IsStopped == true
				) {
					record.IsStopped = false;
					stoppedCases.add(record);
				}
			}
		}
		return stoppedCases;
	}

	/**
	 * @description pause cases when sub statuses are changed
	 * @author Remario Richards | 09-03-2023
	 * @param records
	 **/
	public static void processAutomaticSLAPauseScenarios(List<Case> records) {
		Map<String, String> subStatusesReasonsMap = new Map<String, String>();
		General_Entitlement_Config__mdt config  = getGeneralConfig('General');
		String[] reasons = config.Pause_Reasons__c.split('\n');
		for (String reason : reasons) {
			subStatusesReasonsMap.put(reason.trim(), reason.trim());
		}
		for (Case record : records) {
			for (String key : subStatusesReasonsMap.keySet()) {
				if (
					record.Sub_Status_FS__c != null &&
					record.Sub_Status_FS__c == key &&
					record.IsStopped == false
				) {
					record.SLA_Pause_Reason_list__c = subStatusesReasonsMap.get(key);
					record.IsStopped = true;
				}
			}
		}
	}
	/**
	 * @description process cases that were just unstopped
	 * @author Remario Richards | 09-02-2023
	 * @param stoppedCases
	 **/
	public static void processUnStoppedCases(
		List<Case> records,
		Map<Id, Case> oldCases,
		Map<Id, Account> merchantAccounts
	) {
		for (Case record : records) {
			record.Accumulated_Paused_Time__c = calculatePausedTimeDifference(
				oldCases.get(record.id)?.StopStartDate,
				record,
				System.now(),
				merchantAccounts
			);
		}
	}
	/**
	 * @description calculates the accumulated hours and minutes for stoped cases
	 * @author Remario Richards | 09-02-2023
	 * @param caseRecord
	 * @param endDateTime
	 * @param currentHours
	 * @return String
	 **/
	public static String calculatePausedTimeDifference(
		DateTime startDateTime,
		Case caseRecord,
		DateTime endDateTime,
		Map<Id, Account> merchantAccounts
	) {
		if (startDateTime == null) {
			startDateTime = System.now();
		}
		Integer currentHours = 0;
		Integer currentMinutes = 0;
		if (caseRecord.Accumulated_Paused_Time__c != null) {
			String[] splits = caseRecord.Accumulated_Paused_Time__c.split(':');
			currentHours = Integer.valueOf(splits[0]);
			currentMinutes = Integer.valueOf(splits[1]);
		}

		BusinessHours businessHour = EntitlementSettingWrapper.searchBusinessHourRecordForBank(
			merchantAccounts.get(caseRecord.AccountId).Name
		);
		if (businessHour == null)
			return '';
		// Calculate the elapsed time in milliseconds
		Long elapsedTimeMillis = BusinessHours.diff(
			businessHour.Id,
			startDateTime,
			endDateTime
		);
		// Convert milliseconds to hours and minutes
		Integer elapsedHours = (Integer) (elapsedTimeMillis / (1000 * 60 * 60));
		Integer elapsedMinutes = (Integer) (Math.mod(
			elapsedTimeMillis / (1000 * 60),
			60
		));
		Integer hours = elapsedHours + currentHours;
		Integer minutes = elapsedMinutes + currentMinutes;
		return hours + ':' + minutes;
	}

	/**
	 * @description get non null decimal
	 * @author Remario Richards | 09-02-2023
	 * @param value
	 * @return Decimal
	 **/
	public static Decimal val(Decimal value) {
		return value == null ? 0 : (value);
	}
	/**
	* @description get general configuration
	* @author Remario Richards | 02-01-2024 
	* @param name 
	* @return General_Entitlement_Config__mdt 
	**/
	public static General_Entitlement_Config__mdt getGeneralConfig(String name) {
	 return General_Entitlement_Config__mdt.getInstance(name);
	}

	public static void populateCommunityLink(List<Case> Cases) {
		String currentDomain = System.URL.getOrgDomainUrl().getHost();
		Boolean isProduction = !currentDomain.contains('sandbox');

		String sandboxSuffix = '';
		if (!isProduction) {
			Integer startIndex = currentDomain.indexOf('--') + 2;
			Integer endIndex = currentDomain.indexOf('.sandbox');
			sandboxSuffix = currentDomain.substring(startIndex, endIndex);
		}

		String baseLink = 'https://mcs-prod' + (isProduction ? '' : '--' + sandboxSuffix + '.sandbox') + '.my.site.com/mcs/s/';

		List<Case> casesToUpdate = new List<Case>();

		for (Case c : Cases) {
			if (String.isBlank(c.LinkCommunityMCS__c)) {
				Case caseUpdate = new Case(
					Id = c.Id,
					LinkCommunityMCS__c = baseLink + 'case/' + c.Id + '/detail'
				);
				casesToUpdate.add(caseUpdate);
			}
		}
		if (!casesToUpdate.isEmpty()) {
			update casesToUpdate;
		}
	}
}