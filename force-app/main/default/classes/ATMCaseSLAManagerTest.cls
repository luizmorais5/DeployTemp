@isTest
private class ATMCaseSLAManagerTest {

    @testSetup
    static void setup() {
        OperatingHours oh = new OperatingHours();
		oh.Name = 'TestOH';
		insert oh;
		
		ServiceTerritory serviceTerritory = new ServiceTerritory(
			Name = 'ATM Kingston',
			IsActive = true,
			OperatingHoursId = oh.Id,
            Street = '456 Secondary Street',
            City = 'Kingston',
            State = 'Kingston',
            Country = 'Jamaica'
		);
		insert serviceTerritory;
        
        Account acc = new Account(Name = 'JPS & Partners Co-op Credit Union');
        insert acc;

        Merchant_Location__c merchantLocation = new Merchant_Location__c(
            Address_1_text__c = '123 Main Street',
            Parish_Province_State_list__c = 'Kingston',
            Country_list__c = 'Jamaica',
            Service_Territory_Id__c = serviceTerritory.Id
        );
        insert merchantLocation;
        
        Entitlement ent = new Entitlement(
            Name = 'ATM JPS & Partners Co-op Credit Union',
            StartDate = System.today(),
            AccountId = acc.Id);

        insert ent;

        Entitlement ent2 = new Entitlement(
            Name = 'ATM JPS & Partners Co-op Credit Union Severity 1 Within 35km H & S Installation/Repairs',
            StartDate = System.today(),
            AccountId = acc.Id);

        insert ent2;
    }

    @isTest
    static void testPopulateATMHubLocation() {
        RecordType atmRecordType = [
            SELECT Id FROM RecordType WHERE DeveloperName = 'ATM' LIMIT 1
        ];
        
        Merchant_Location__c merchantLocation = [
            SELECT Id FROM Merchant_Location__c LIMIT 1
        ];
        
        Case testCase = new Case(
            RecordTypeId = atmRecordType.Id,
            Merchant_Location_Id__c = merchantLocation.Id
        );
        
        Test.startTest();
        insert testCase;
        Test.stopTest();
        
        merchantLocation = [
            SELECT Service_Hub_Id__c FROM Merchant_Location__c WHERE Id = :merchantLocation.Id
        ];
        
        ServiceTerritory serviceTerritory = [
            SELECT Id FROM ServiceTerritory WHERE Name = 'ATM Kingston' LIMIT 1
        ];
        
        System.assertEquals(serviceTerritory.Id, merchantLocation.Service_Hub_Id__c, 'Service Hub Id should have been populated based on the Parish');
    }

    @isTest
    static void testCalculateKilometerRadius() {
        RecordType atmRecordType = [SELECT Id FROM RecordType WHERE DeveloperName = 'ATM' LIMIT 1];

        Merchant_Location__c merchantLocation = [SELECT Id FROM Merchant_Location__c LIMIT 1];

        Case testCase = new Case(
            RecordTypeId = atmRecordType.Id,
            Merchant_Location_Id__c = merchantLocation.Id
        );
        insert testCase;

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new GoogleDistanceMatrixMock());

        ATMCaseSLAManager.calculateKilometerRadius(new List<Case>{testCase}, new Map<Id, Case>());
        Test.stopTest();

        merchantLocation = [SELECT KilometerRadius__c FROM Merchant_Location__c WHERE Id = :merchantLocation.Id];
        System.assertNotEquals(null, merchantLocation.KilometerRadius__c, 'Kilometer radius should have been calculated');
    }

    @isTest
    static void testProcessLocationsAsync() {
        Merchant_Location__c merchantLocation = [SELECT Id FROM Merchant_Location__c LIMIT 1];
        RecordType atmRecordType = [SELECT Id FROM RecordType WHERE DeveloperName = 'ATM' LIMIT 1];

        Case testCase = new Case(
            RecordTypeId = atmRecordType.Id,
            Merchant_Location_Id__c = merchantLocation.Id
        );
        
        insert testCase;

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new GoogleDistanceMatrixMock());
        DistanceFutureHelper.processLocationsAsync(new List<Id>{merchantLocation.Id}, new List<Id>{testCase.Id});
        Test.stopTest();

        merchantLocation = [SELECT KilometerRadius__c FROM Merchant_Location__c WHERE Id = :merchantLocation.Id];
        System.assertNotEquals(null, merchantLocation.KilometerRadius__c, 'Kilometer radius should have been calculated');
    }

    @isTest
    static void testProcessATMSlaCases() {
        RecordType atmRecordType = [SELECT Id FROM RecordType WHERE DeveloperName = 'ATM' LIMIT 1];
        Merchant_Location__c merchantLocation = [SELECT Id FROM Merchant_Location__c LIMIT 1];
        Account acc = [SELECT Id FROM Account WHERE Name = 'JPS & Partners Co-op Credit Union' LIMIT 1];

        merchantLocation.KilometerRadius__c = '5';
        merchantLocation.Customer_Account_ID__c = acc.Id;

        update merchantLocation;

        Case testCase = new Case(
            RecordTypeId = atmRecordType.Id,
            AccountId = acc.Id,
            Severity__c = '1',
            Charge_Type_list__c = 'SLA Call',
            Service_Type_list__c = 'ATM Repair',
            Merchant_Location_Id__c = merchantLocation.Id
        );

        Test.startTest();
        insert testCase;
        Test.stopTest();

        Case updated = [SELECT EntitlementId FROM Case WHERE Id = :testCase.Id];
        System.assertNotEquals(null, updated.EntitlementId, 'EntitlementId should have been assigned by processATMSlaCases');
    }
}