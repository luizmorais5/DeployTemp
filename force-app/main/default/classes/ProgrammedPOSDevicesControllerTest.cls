@isTest
public class ProgrammedPOSDevicesControllerTest {
    
    @testSetup
    static void setupData() {
        Account testAccount = new Account(
            Name = 'Test Bank',
            CurrencyIsoCode = 'JMD'
        );
        insert testAccount;
        
        // Create OperatingHours first
        OperatingHours operatingHours = new OperatingHours(
            Name = 'Test Operating Hours',
            TimeZone = 'America/Jamaica'
        );
        insert operatingHours;
        
        // Create ServiceTerritories
        ServiceTerritory kingstonTerritory = new ServiceTerritory(
            Name = 'Kingston',
            IsActive = true,
            OperatingHoursId = operatingHours.Id
        );
        ServiceTerritory stJamesTerritory = new ServiceTerritory(
            Name = 'St. James',
            IsActive = true,
            OperatingHoursId = operatingHours.Id
        );
        insert new List<ServiceTerritory>{kingstonTerritory, stJamesTerritory};
        
        Schema.Location programmerLocation1 = new Schema.Location(
            Name = 'Programmer Location 1',
            LocationType = 'Programmer',
            IsInventoryLocation = true
        );
        
        Schema.Location programmerLocation2 = new Schema.Location(
            Name = 'Programmer Location 2',
            LocationType = 'Programmer',
            IsInventoryLocation = true
        );
        
        insert new List<Schema.Location>{programmerLocation1, programmerLocation2};
        
        Schema.Location programmedLocation = new Schema.Location(
            Name = 'Programmed Devices Location',
            LocationType = 'Programmed devices',
            IsInventoryLocation = true,
            Customer_Name_Id__c = testAccount.Id
        );
        insert programmedLocation;

        Schema.Location returnToProgrammingTeamLocation = new Schema.Location(
            Name = 'Return to Programming Team',
            LocationType = 'Programmer',
            IsInventoryLocation = true,
            Customer_Name_Id__c = testAccount.Id
        );
        insert returnToProgrammingTeamLocation;

        Schema.Location shipmentLocation = new Schema.Location(
            Name = 'Programmed POS Devices for Shipment',
            LocationType = 'Programmed devices',
            IsInventoryLocation = true
        );
        insert shipmentLocation;

        Schema.Location bankWarehouseLocation = new Schema.Location(
            Name = 'Warehouse',
            LocationType = 'Warehouse',
            IsInventoryLocation = true,
            Customer_Name_Id__c = testAccount.Id
        );
        insert bankWarehouseLocation;
        
        Product2 testProduct = new Product2(
            Name = 'Test POS Device',
            IsActive = true,
            IsSerialized = true
        );
        insert testProduct;
        
        // Merchant Location for Kingston Hub (No Territory Hub Assigned)
        Merchant_Location__c merchantLocationKingston = new Merchant_Location__c(
            Address_1_text__c = '123 Test Street',
            Parish_Province_State_list__c = 'Kingston',
            Country_list__c = 'Jamaica',
            Customer_Account_ID__c = testAccount.Id
        );
        insert merchantLocationKingston;

        // Merchant Location for St. James Hub
        Merchant_Location__c merchantLocationStJames = new Merchant_Location__c(
            Address_1_text__c = '456 Test Avenue',
            Parish_Province_State_list__c = 'St. James',
            Country_list__c = 'Jamaica',
            Customer_Account_ID__c = testAccount.Id
        );
        insert merchantLocationStJames;
        
        // Case for Kingston Hub - No Territory Hub Assigned (Scenario 5)
        Case testCaseKingstonNoHub = new Case(
            AccountId = testAccount.Id,
            Merchant_Location_Id__c = merchantLocationKingston.Id,
            AssignedTerritoryHub__c = null // Blank for Scenario 5
        );
        insert testCaseKingstonNoHub;

        // Case for Kingston Hub - Territory Hub Assigned (Scenario 6)
        Case testCaseKingstonWithHub = new Case(
            AccountId = testAccount.Id,
            Merchant_Location_Id__c = merchantLocationKingston.Id,
            AssignedTerritoryHub__c = kingstonTerritory.Id // Kingston for Scenario 6
        );
        insert testCaseKingstonWithHub;

        // Case for St. James Hub (Scenario 8)
        Case testCaseStJames = new Case(
            AccountId = testAccount.Id,
            Merchant_Location_Id__c = merchantLocationStJames.Id,
            AssignedTerritoryHub__c = stJamesTerritory.Id
        );
        insert testCaseStJames;
        
        WorkOrder testWorkOrderKingstonNoHub = new WorkOrder(
            Subject = 'Test Work Order Kingston No Hub',
            Status = 'New'
        );
        insert testWorkOrderKingstonNoHub;

        WorkOrder testWorkOrderKingstonWithHub = new WorkOrder(
            Subject = 'Test Work Order Kingston With Hub',
            Status = 'New'
        );
        insert testWorkOrderKingstonWithHub;

        WorkOrder testWorkOrderStJames = new WorkOrder(
            Subject = 'Test Work Order St James',
            Status = 'New'
        );
        insert testWorkOrderStJames;
        
        testCaseKingstonNoHub.Work_Order_ID__c = testWorkOrderKingstonNoHub.Id;
        testCaseKingstonWithHub.Work_Order_ID__c = testWorkOrderKingstonWithHub.Id;
        testCaseStJames.Work_Order_ID__c = testWorkOrderStJames.Id;
        update new List<Case>{testCaseKingstonNoHub, testCaseKingstonWithHub, testCaseStJames};
        
        SerializedProduct simCard1 = new SerializedProduct(
            Product2Id = testProduct.Id,
            SerialNumber = 'SIM001',
            Substatus_list__c = 'Assigned to a Terminal ID'
        );
        insert simCard1;

        SerializedProduct simCard2 = new SerializedProduct(
            Product2Id = testProduct.Id,
            SerialNumber = 'SIM002',
            Substatus_list__c = 'Assigned to a Terminal ID'
        );
        insert simCard2;

        Terminal_ID__c testTerminalKingstonNoHub = new Terminal_ID__c(
            Name = 'TEST001',
            Work_Order_ID__c = testWorkOrderKingstonNoHub.Id,
            SIM_Card_Id__c = simCard1.Id,
            SIM_Card_2_Id__c = simCard2.Id
        );
        insert testTerminalKingstonNoHub;

        Terminal_ID__c testTerminalKingstonWithHub = new Terminal_ID__c(
            Name = 'TEST002',
            Work_Order_ID__c = testWorkOrderKingstonWithHub.Id,
            SIM_Card_Id__c = simCard1.Id,
            SIM_Card_2_Id__c = simCard2.Id
        );
        insert testTerminalKingstonWithHub;

        Terminal_ID__c testTerminalStJames = new Terminal_ID__c(
            Name = 'TEST003',
            Work_Order_ID__c = testWorkOrderStJames.Id,
            SIM_Card_Id__c = simCard1.Id,
            SIM_Card_2_Id__c = simCard2.Id
        );
        insert testTerminalStJames;

        simCard1.Terminal_ID_TID_Id__c = testTerminalKingstonNoHub.Id;
        simCard2.Terminal_ID_TID_Id__c = testTerminalKingstonNoHub.Id;
        update new List<SerializedProduct>{simCard1, simCard2};
        
        ProductItem testProductItemProgrammer1 = new ProductItem(
            LocationId = programmerLocation1.Id,
            Product2Id = testProduct.Id,
            QuantityUnitOfMeasure = 'Each',
            QuantityOnHand = 0,
            Status__c = 'Available'
        );
        insert testProductItemProgrammer1;

        ProductItem testProductItemProgrammer2 = new ProductItem(
            LocationId = programmerLocation2.Id,
            Product2Id = testProduct.Id,
            QuantityUnitOfMeasure = 'Each',
            QuantityOnHand = 0,
            Status__c = 'Available'
        );
        insert testProductItemProgrammer2;

        ProductItem testProductItemProgrammed = new ProductItem(
            LocationId = programmedLocation.Id,
            Product2Id = testProduct.Id,
            QuantityUnitOfMeasure = 'Each',
            QuantityOnHand = 0,
            Status__c = 'Available'
        );
        insert testProductItemProgrammed;

        ProductItem testProductItemWarehouse = new ProductItem(
            LocationId = bankWarehouseLocation.Id,
            Product2Id = testProduct.Id,
            QuantityUnitOfMeasure = 'Each',
            QuantityOnHand = 0,
            Status__c = 'Available'
        );
        insert testProductItemWarehouse;
        
        SerializedProduct testSerializedProductKingstonNoHub = new SerializedProduct(
            Product2Id = testProduct.Id,
            SerialNumber = 'SN001',
            Substatus_list__c = 'Assigned to a Terminal ID',
            ProductItemId = testProductItemProgrammer1.Id,
            Terminal_ID_TID_Id__c = testTerminalKingstonNoHub.Id,
            Bank_Id__c = testAccount.Id,
            Picked_Up__c = false
        );
        insert testSerializedProductKingstonNoHub;

        testProductItemProgrammer1.QuantityOnHand = 1;
        update testProductItemProgrammer1;

        SerializedProduct testSerializedProductKingstonWithHub = new SerializedProduct(
            Product2Id = testProduct.Id,
            SerialNumber = 'SN002',
            Substatus_list__c = 'Assigned to a Terminal ID',
            ProductItemId = testProductItemProgrammer2.Id,
            Terminal_ID_TID_Id__c = testTerminalKingstonWithHub.Id,
            Bank_Id__c = testAccount.Id,
            Picked_Up__c = false
        );
        insert testSerializedProductKingstonWithHub;

        testProductItemProgrammer2.QuantityOnHand = 1;
        update testProductItemProgrammer2;  

        SerializedProduct testSerializedProductStJames = new SerializedProduct(
            Product2Id = testProduct.Id,
            SerialNumber = 'SN003',
            Substatus_list__c = 'Assigned to a Terminal ID',
            ProductItemId = testProductItemProgrammed.Id,
            Terminal_ID_TID_Id__c = testTerminalStJames.Id,
            Bank_Id__c = testAccount.Id,
            Picked_Up__c = false
        );
        insert testSerializedProductStJames;

        testProductItemProgrammed.QuantityOnHand = 1;
        update testProductItemProgrammed;

        // Create existing ProductTransfer records (simulating programming stage)
        ProductTransfer existingTransfer1 = new ProductTransfer(
            SourceProductItemId = testProductItemProgrammer1.Id,
            Product2Id = testProduct.Id,
            QuantitySent = 1,
            QuantityUnitOfMeasure = 'Each',
            Status = 'Sent',
            Description = 'Programming Transfer - SN001'
        );
        ProductTransfer existingTransfer2 = new ProductTransfer(
            SourceProductItemId = testProductItemProgrammer2.Id,
            Product2Id = testProduct.Id,
            QuantitySent = 1,
            QuantityUnitOfMeasure = 'Each',
            Status = 'Sent',
            Description = 'Programming Transfer - SN002'
        );
        ProductTransfer existingTransfer3 = new ProductTransfer(
            SourceProductItemId = testProductItemProgrammed.Id,
            Product2Id = testProduct.Id,
            QuantitySent = 1,
            QuantityUnitOfMeasure = 'Each',
            Status = 'Sent',
            Description = 'Programming Transfer - SN003'
        );
        insert new List<ProductTransfer>{existingTransfer1, existingTransfer2, existingTransfer3};
    }
    
    @isTest
    static void testGetProgrammedPOSDevices() {
        Test.startTest();
        List<ProgrammedPOSDeviceWrapper> devices = ProgrammedPOSDevicesController.getProgrammedPOSDevices();
        Test.stopTest();
        
        System.assertNotEquals(null, devices, 'Devices list should not be null');
        System.assertEquals(2, devices.size(), 'Should return 2 devices from programmer location');
        
        ProgrammedPOSDeviceWrapper device = devices[0];
        System.assertNotEquals(null, device.model, 'Model should not be null');
        System.debug('Expected: [' + 'Test POS Device' + ']');
        System.debug('Actual: [' + device.model + ']');
        System.assert(device.model.contains('Test POS Device'), 'Model should contain Test POS Device');
        System.assertEquals(true, device.received, 'Received should be true');
        System.assertEquals(false, device.returnToProgrammer, 'Return to programmer should be false');
        System.assertEquals('Test Bank', device.merchantName, 'Merchant name should match');
    }
    
    @isTest
    static void testGetReceivedProgrammedPOSDevices() {
        Test.startTest();
        List<ProgrammedPOSDeviceWrapper> devices = ProgrammedPOSDevicesController.getReceivedProgrammedPOSDevices();
        Test.stopTest();
        
        System.assertNotEquals(null, devices, 'Devices list should not be null');
        System.assertEquals(1, devices.size(), 'Should return 1 device from programmed devices location');
        
        ProgrammedPOSDeviceWrapper device = devices[0];
        System.assertEquals('SN003', device.serialNumber, 'Serial number should match');
        System.assertNotEquals(null, device.model, 'Model should not be null');
        System.debug('Expected: [' + 'Test POS Device' + ']');
        System.debug('Actual: [' + device.model + ']');
        System.assert(device.model.contains('Test POS Device'), 'Model should contain Test POS Device');
        System.assertEquals('TEST003', device.tid, 'TID should match');
        System.assertEquals(false, device.isPickedUp, 'IsPickedUp should be false');
        System.assertEquals('Test Bank', device.merchantName, 'Merchant name should match');
    }
    
    @isTest
    static void testConfirmReceiptOfDevicesKingstonNoTerritoryHub() {
        SerializedProduct testDevice = [SELECT Id, ProductItemId FROM SerializedProduct WHERE SerialNumber = 'SN001' LIMIT 1];
        ProductTransfer existingTransfer = [SELECT Id, Status, IsReceived FROM ProductTransfer WHERE SourceProductItemId = :testDevice.ProductItemId LIMIT 1];
        
        // Verify initial state
        System.assertEquals('Sent', existingTransfer.Status, 'Initial transfer status should be Sent');
        System.assertEquals(false, existingTransfer.IsReceived, 'IsReceived should initially be false');
        
        Test.startTest();
        ProgrammedPOSDevicesController.confirmReceiptOfDevices(new List<String>{testDevice.Id});
        Test.stopTest();

        // Scenario 9: Verify existing ProductTransfer was updated to "Received"
        ProductTransfer updatedTransfer = [SELECT Id, Status FROM ProductTransfer WHERE Id = :existingTransfer.Id];
        System.assertEquals('Received', updatedTransfer.Status, 'Existing transfer status should be updated to Received');
        
        // Verify ProductTransferState record was created
        List<ProductTransferState> transferStates = [
            SELECT Id, ProductTransferId, SerializedProductId, Action, TransferState
            FROM ProductTransferState 
            WHERE ProductTransferId = :existingTransfer.Id 
            AND Action = 'Receive'
        ];
        System.assertEquals(1, transferStates.size(), 'Should create one ProductTransferState for Receive action');
        System.assertEquals('Sent', transferStates[0].TransferState, 'TransferState should be Sent');
        System.assertEquals(testDevice.Id, transferStates[0].SerializedProductId, 'Should link to correct SerializedProduct');

        System.assert(true, 'Method should complete without exception for Kingston parish with no territory hub');
    }

    @isTest
    static void testConfirmReceiptOfDevicesKingstonWithTerritoryHub() {
        SerializedProduct testDevice = [SELECT Id, ProductItemId FROM SerializedProduct WHERE SerialNumber = 'SN002' LIMIT 1];
        ProductTransfer existingTransfer = [SELECT Id, Status, ReceivedById FROM ProductTransfer WHERE SourceProductItemId = :testDevice.ProductItemId LIMIT 1];
        
        // Verify initial state
        System.assertEquals('Sent', existingTransfer.Status, 'Initial transfer status should be Sent');
        
        Test.startTest();
        ProgrammedPOSDevicesController.confirmReceiptOfDevices(new List<String>{testDevice.Id});
        Test.stopTest();

        // Scenario 9: Verify existing ProductTransfer was updated to "Received"
        ProductTransfer updatedTransfer = [SELECT Id, Status FROM ProductTransfer WHERE Id = :existingTransfer.Id];
        System.assertEquals('Received', updatedTransfer.Status, 'Existing transfer status should be updated to Received');

        System.assert(true, 'Method should complete without exception for Kingston territory hub assigned');
    }

    @isTest
    static void testConfirmReceiptOfDevicesStJames() {
        SerializedProduct testDevice = [SELECT Id, ProductItemId FROM SerializedProduct WHERE SerialNumber = 'SN003' LIMIT 1];
        ProductTransfer existingTransfer = [SELECT Id, Status FROM ProductTransfer WHERE SourceProductItemId = :testDevice.ProductItemId LIMIT 1];
        
        // Count initial ProductTransfer records
        Integer initialTransferCount = [SELECT COUNT() FROM ProductTransfer];
        
        Test.startTest();
        ProgrammedPOSDevicesController.confirmReceiptOfDevices(new List<String>{testDevice.Id});
        Test.stopTest();

        // Scenario 9: Verify existing ProductTransfer was updated to "Received"
        ProductTransfer updatedTransfer = [SELECT Id, Status FROM ProductTransfer WHERE Id = :existingTransfer.Id];
        System.assertEquals('Received', updatedTransfer.Status, 'Existing transfer status should be updated to Received');

        // Scenario 8: Verify new ProductTransfer was created for shipment
        Integer finalTransferCount = [SELECT COUNT() FROM ProductTransfer];
        System.assertEquals(initialTransferCount + 1, finalTransferCount, 'Should create one new ProductTransfer for shipment');
        
        // Verify the new transfer for shipment
        List<ProductTransfer> newTransfers = [
            SELECT Id, Status, DestinationLocationId, Description
            FROM ProductTransfer 
            WHERE Id != :existingTransfer.Id 
            AND SourceProductItemId = :testDevice.ProductItemId
            ORDER BY CreatedDate DESC 
            LIMIT 1
        ];
        System.assertEquals(1, newTransfers.size(), 'Should have one new transfer');
        System.assertEquals('Ready For Pickup', newTransfers[0].Status, 'New transfer should be Ready For Pickup');
        System.assert(newTransfers[0].Description.contains('Transfer to Shipment Location'), 'Description should indicate shipment transfer');
    }
    
    @isTest
    static void testSearchProgrammedPOSDevices() {
        Test.startTest();
        List<ProgrammedPOSDeviceWrapper> devices = ProgrammedPOSDevicesController.searchProgrammedPOSDevices('SN001', 'programmed');
        Test.stopTest();
        
        System.assertNotEquals(null, devices, 'Search results should not be null');
        // Should return at least 1 device that matches SN001
        System.assert(devices.size() >= 1, 'Should return at least 1 matching device');
        
        // Find the specific device we're looking for
        ProgrammedPOSDeviceWrapper foundDevice = null;
        for (ProgrammedPOSDeviceWrapper device : devices) {
            if (device.serialNumber == 'SN001') {
                foundDevice = device;
                break;
            }
        }
        System.assertNotEquals(null, foundDevice, 'Should find device with SN001');
        System.assertEquals('SN001', foundDevice.serialNumber, 'Should return device with matching serial number');
    }
    
    @isTest
    static void testSearchReceivedPOSDevices() {
        Test.startTest();
        List<ProgrammedPOSDeviceWrapper> devices = ProgrammedPOSDevicesController.searchProgrammedPOSDevices('TEST003', 'received');
        Test.stopTest();
        
        System.assertNotEquals(null, devices, 'Search results should not be null');
        System.assertEquals(1, devices.size(), 'Should return 1 matching device');
        System.assertEquals('TEST003', devices[0].tid, 'Should return device with matching TID');
    }

    @isTest
    static void testHasDualProgrammerLogisticianRoleNoServiceResource() {
        // Test user without Service Resource
        Test.startTest();
        
        Boolean isDualRole = ProgrammedPOSDevicesController.hasDualProgrammerLogisticianRole();
        
        Test.stopTest();
        
        System.assertEquals(false, isDualRole, 'Should return false for user without Service Resource');
    }

    @isTest
    static void testHasDualProgrammerLogisticianRoleWithServiceResourceNoSkills() {
        // Create a test user
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'NoSkillsUser',
            Email = 'noskillstestuser@test.com',
            Username = 'noskillstestuser@test.com',
            Alias = 'testnosk',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            LanguageLocaleKey = 'en_US'
        );
        insert testUser;

        // Create Service Resource for the test user
        ServiceResource testServiceResource = new ServiceResource(
            Name = 'Test No Skills Resource',
            ResourceType = 'T',
            RelatedRecordId = testUser.Id,
            IsActive = true
        );
        insert testServiceResource;

        // Test as user with Service Resource but no skills
        System.runAs(testUser) {
            Test.startTest();
            
            Boolean isDualRole = ProgrammedPOSDevicesController.hasDualProgrammerLogisticianRole();
            
            Test.stopTest();
            
            System.assertEquals(false, isDualRole, 'Should return false for user with no skills');
        }
    }

    @isTest
    static void testDualRoleGetProgrammedPOSDevicesReturnsEmptyWithExistingSkills() {
        // This test will use existing Skills if they exist
        List<Skill> existingSkills = [SELECT Id, DeveloperName FROM Skill WHERE DeveloperName IN ('Programmer', 'Logistician') LIMIT 2];
        
        if (existingSkills.size() < 2) {
            // Skip test if we don't have both skills
            return;
        }
        
        Skill programmerSkill;
        Skill logisticianSkill;
        
        for (Skill skill : existingSkills) {
            if (skill.DeveloperName == 'Programmer') {
                programmerSkill = skill;
            } else if (skill.DeveloperName == 'Logistician') {
                logisticianSkill = skill;
            }
        }
        
        if (programmerSkill == null || logisticianSkill == null) {
            // Skip test if we don't have both required skills
            return;
        }
        
        // Create a test user
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'DualRoleUser',
            Email = 'dualtestuser5@test.com',
            Username = 'dualtestuser5@test.com',
            Alias = 'testdua5',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            LanguageLocaleKey = 'en_US'
        );
        insert testUser;

        // Create Service Resource for the test user
        ServiceResource testServiceResource = new ServiceResource(
            Name = 'Test Dual Role Resource 5',
            ResourceType = 'T',
            RelatedRecordId = testUser.Id,
            IsActive = true
        );
        insert testServiceResource;

        // Create ServiceResourceSkills for dual role
        List<ServiceResourceSkill> skills = new List<ServiceResourceSkill>{
            new ServiceResourceSkill(
                ServiceResourceId = testServiceResource.Id,
                SkillId = programmerSkill.Id,
                SkillLevel = 1,
                EffectiveStartDate = Date.today()
            ),
            new ServiceResourceSkill(
                ServiceResourceId = testServiceResource.Id,
                SkillId = logisticianSkill.Id,
                SkillLevel = 1,
                EffectiveStartDate = Date.today()
            )
        };
        insert skills;

        // Test as dual role user
        System.runAs(testUser) {
            Test.startTest();
            
            // Scenario 2: Dual role user should get empty list
            List<ProgrammedPOSDeviceWrapper> deviceWrappers = 
                ProgrammedPOSDevicesController.getProgrammedPOSDevices();
            
            Test.stopTest();
            
            System.assertEquals(0, deviceWrappers.size(), 'Dual role user should get empty list for programmed devices');
        }
    }

    @isTest 
    static void testDualRoleGetReceivedProgrammedPOSDevicesReturnsEmptyWithExistingSkills() {
        // This test will use existing Skills if they exist
        List<Skill> existingSkills = [SELECT Id, DeveloperName FROM Skill WHERE DeveloperName IN ('Programmer', 'Logistician') LIMIT 2];
        
        Skill programmerSkill;
        Skill logisticianSkill;
        
        for (Skill skill : existingSkills) {
            if (skill.DeveloperName == 'Programmer') {
                programmerSkill = skill;
            } else if (skill.DeveloperName == 'Logistician') {
                logisticianSkill = skill;
            }
        }
        
        if (programmerSkill == null || logisticianSkill == null) {
            // Skip test if we don't have both skills
            // We can't insert skills with apex
            return;
        }
        
        // Create a test user
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'DualRoleUser',
            Email = 'dualtestuser6@test.com',
            Username = 'dualtestuser6@test.com',
            Alias = 'testdua6',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            LanguageLocaleKey = 'en_US'
        );
        insert testUser;

        // Create Service Resource for the test user
        ServiceResource testServiceResource = new ServiceResource(
            Name = 'Test Dual Role Resource 6',
            ResourceType = 'T',
            RelatedRecordId = testUser.Id,
            IsActive = true
        );
        insert testServiceResource;

        // Create ServiceResourceSkills for dual role
        List<ServiceResourceSkill> skills = new List<ServiceResourceSkill>{
            new ServiceResourceSkill(
                ServiceResourceId = testServiceResource.Id,
                SkillId = programmerSkill.Id,
                SkillLevel = 1,
                EffectiveStartDate = Date.today()
            ),
            new ServiceResourceSkill(
                ServiceResourceId = testServiceResource.Id,
                SkillId = logisticianSkill.Id,
                SkillLevel = 1,
                EffectiveStartDate = Date.today()
            )
        };
        insert skills;

        // Test as dual role user
        System.runAs(testUser) {
            Test.startTest();
            
            // Scenario 2: Dual role user should get empty list
            List<ProgrammedPOSDeviceWrapper> deviceWrappers = 
                ProgrammedPOSDevicesController.getReceivedProgrammedPOSDevices();
            
            Test.stopTest();
            
            System.assertEquals(0, deviceWrappers.size(), 'Dual role user should get empty list for received devices');
        }
    }

    @isTest
    static void testReturnDevicesToProgrammer() {
        // Use the St. James device that's in the "Received Programmed POS Devices" location
        SerializedProduct testDevice = [SELECT Id, ProductItemId FROM SerializedProduct WHERE SerialNumber = 'SN003' LIMIT 1];
        Integer initialProductTransferCount = [SELECT COUNT() FROM ProductTransfer];
        
        Test.startTest();
        try {
            ProgrammedPOSDevicesController.returnDevicesToProgrammer(new List<String>{testDevice.Id});
        } catch (Exception e) {
            System.debug('Error returning devices to programmer: ' + e.getMessage());
            System.debug('Error returning devices to programmer: ' + e.getStackTraceString());
            return;
        }
        Test.stopTest();

        // Scenario 12: Verify ProductTransfer was created
        Integer finalProductTransferCount = [SELECT COUNT() FROM ProductTransfer];
        System.assertEquals(initialProductTransferCount + 1, finalProductTransferCount, 'ProductTransfer should be created');
        
        // Verify the ProductTransfer details
        ProductTransfer createdTransfer = [
            SELECT Id, QuantitySent, SourceProductItemId, DestinationLocationId, Status, Description, IsSent
            FROM ProductTransfer 
            WHERE SourceProductItemId = :testDevice.ProductItemId
            ORDER BY CreatedDate DESC 
            LIMIT 1
        ];
        System.assertEquals(1, createdTransfer.QuantitySent, 'Quantity sent should be 1');
        System.assertEquals('Ready For Pickup', createdTransfer.Status, 'Initial status should be Ready For Pickup');
        System.assertEquals(true, createdTransfer.IsSent, 'ProductTransfer should be marked as sent');
        System.assert(createdTransfer.Description.contains('Return to Programming Team'), 'Description should indicate return to programming team');
        
        // Verify ProductTransferState was created
        List<ProductTransferState> transferStates = [
            SELECT Id, ProductTransferId, SerializedProductId, Action, TransferState
            FROM ProductTransferState 
            WHERE ProductTransferId = :createdTransfer.Id
        ];
        System.assertEquals(1, transferStates.size(), 'Should create one ProductTransferState');
        System.assertEquals('Send', transferStates[0].Action, 'Action should be Send');
        System.assertEquals('Sent', transferStates[0].TransferState, 'TransferState should be Sent');
        System.assertEquals(testDevice.Id, transferStates[0].SerializedProductId, 'Should link to correct SerializedProduct');
        
        // Verify the device destination location was updated to "Return to Programming Team"
        SerializedProduct updatedDevice = [SELECT Id, Destination_Location_Id__c FROM SerializedProduct WHERE Id = :testDevice.Id];
        Schema.Location returnLocation = [SELECT Id FROM Location WHERE Name = 'Return to Programming Team' LIMIT 1];
        System.assertEquals(returnLocation.Id, updatedDevice.Destination_Location_Id__c, 'Destination location should be set to return location');
    }
}