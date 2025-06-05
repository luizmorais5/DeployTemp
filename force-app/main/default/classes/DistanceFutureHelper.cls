public without sharing class DistanceFutureHelper {

	@future(callout=true)
	public static void processLocationsAsync(List<Id> merchantLocationIds, List<Id> casesIds) {
		Map<Id, Merchant_Location__c> merchantLocations = new Map<Id, Merchant_Location__c>(
			[SELECT Id, Address_1_text__c, Parish_Province_State_list__c, Country_list__c, 
					Service_Territory_Id__c, KilometerRadius__c
			FROM Merchant_Location__c
			WHERE Id IN :merchantLocationIds]
		);

		Set<Id> serviceTerritoryIds = new Set<Id>();
		for (Merchant_Location__c loc : merchantLocations.values()) {
			if (loc.Service_Territory_Id__c != null && loc.KilometerRadius__c == null) {
				serviceTerritoryIds.add(loc.Service_Territory_Id__c);
			}
		}

		Map<Id, ServiceTerritory> serviceTerritories = new Map<Id, ServiceTerritory>(
			[SELECT Id,
					Street, 
					City, 
					State, 
					Country 
			FROM 
				ServiceTerritory
			WHERE Id IN :serviceTerritoryIds]
		);

		List<Merchant_Location__c> locationsToUpdate = new List<Merchant_Location__c>();

		for (Merchant_Location__c loc : merchantLocations.values()) {
			if (loc.KilometerRadius__c != null || loc.Service_Territory_Id__c == null) continue;

			ServiceTerritory territory = serviceTerritories.get(loc.Service_Territory_Id__c);
			if (territory == null) continue;

			String originAddress = formatTerritoryAddress(territory);
			String destinationAddress = formatMerchantAddress(loc);

			try {
				GoogleDistanceMatrixService service = new GoogleDistanceMatrixService();
				System.debug('>>>>>> originAddress: ' + originAddress);
				System.debug('>>>>>> destinationAddress ' + destinationAddress);

				if (String.isBlank(originAddress) || String.isBlank(destinationAddress)) {
					System.debug('Incomplete address data for Merchant Location ' + loc.Id + '. Skipping distance calculation.');
					continue;
				}

				DistanceMatrixResult result = service.getDistanceAndTime(originAddress, destinationAddress);

				if (result != null && !String.isBlank(result.distanceText)) {
					loc.KilometerRadius__c = convertDistance(result.distanceText);
					locationsToUpdate.add(loc);
				}
			} catch (Exception e) {
				System.debug('Error to Calculate Radius: ' + loc.Id + ': ' + e.getMessage());
			}
		}

		if (!locationsToUpdate.isEmpty()) {
			update locationsToUpdate;
			updateKmRadiusCalculated(casesIds);
		}
	}

	private static String formatMerchantAddress(Merchant_Location__c loc) {
		List<String> addressParts = new List<String>();
		if (!String.isBlank(loc.Address_1_text__c)) addressParts.add(loc.Address_1_text__c);
		if (!String.isBlank(loc.Parish_Province_State_list__c)) addressParts.add(loc.Parish_Province_State_list__c);
		if (!String.isBlank(loc.Country_list__c)) addressParts.add(loc.Country_list__c);
		return String.join(addressParts, ', ');
	}
	
	private static String formatTerritoryAddress(ServiceTerritory territory) {
		List<String> addressParts = new List<String>();
		if (!String.isBlank(territory.Street)) addressParts.add(territory.Street);
		if (!String.isBlank(territory.City)) addressParts.add(territory.City);
		if (!String.isBlank(territory.State)) addressParts.add(territory.State);
		if (!String.isBlank(territory.Country)) addressParts.add(territory.Country);
		return String.join(addressParts, ', ');
	}
	

	private static String convertDistance(String distanceText) {
		if (distanceText != null) {
			return distanceText.replace('km', '').trim();
		}
		return null;
	}

	private static void updateKmRadiusCalculated(List<Id> casesIds) {
		List<Case> casesToUpdate = new List<Case>();

		casesToUpdate = [SELECT Id FROM Case WHERE Id IN: casesIds];

		for (Case c : casesToUpdate) {
			c.KmRadiusCalculated__c = true;
		}

		update casesToUpdate;
	}
}