@isTest
public class ShippedPOSDevicesControllerTest {

    @testSetup
    static void setup() {
        // Create test account (bank)
        Account testAccount = new Account(
            Name = 'Test Bank'
        );
        insert testAccount;

        // Create test product
        Product2 testProduct = new Product2(
            Name = 'Test POS Device',
            IsActive = true,
            IsSerialized = true
        );
        insert testProduct;

        // Create operating hours for service territory
        OperatingHours operatingHours = new OperatingHours(
            Name = 'TestOH'
        );
        insert operatingHours;

        // Create test service territory
        ServiceTerritory testTerritory = new ServiceTerritory(
            Name = 'Kingston',
            IsActive = true,
            OperatingHoursId = operatingHours.Id
        );
        insert testTerritory;

        // Create test user with territory
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'Logistician',
            Email = 'test.logistician@test.com',
            Username = 'test.logistician@test.com.test',
            Alias = 'testlog',
            TimeZoneSidKey = 'America/Jamaica',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = profile.Id
        );
        insert testUser;

        // Create FSL__User_Territory__c record for the test user
        try {
            FSL__User_Territory__c userTerritory = new FSL__User_Territory__c(
                FSL__User__c = testUser.Id,
                FSL__ServiceTerritory__c = testTerritory.Id
            );
            insert userTerritory;
        } catch (Exception e) {
            System.debug('FSL__User_Territory__c creation failed: ' + e.getMessage());
        }

        // Create locations for different scenarios
        
        // Territory POS Devices location
        Schema.Location territoryLocation = new Schema.Location(
            Name = 'POS Devices for Territories',
            LocationType = 'Programmed devices',
            IsInventoryLocation = true
        );
        insert territoryLocation;

        // Kingston Territory POS Devices location
        Schema.Location kingstonTerritoryLocation = new Schema.Location(
            Name = 'Kingston POS Devices',
            LocationType = 'Programmed devices',
            IsInventoryLocation = true
        );
        insert kingstonTerritoryLocation;

        // Hub location
        Schema.Location hubLocation = new Schema.Location(
            Name = 'Test Hub POS Devices',
            LocationType = 'Programmed devices',
            IsInventoryLocation = true,
            Customer_Name_Id__c = testAccount.Id
        );
        insert hubLocation;

        // Create merchant location
        Merchant_Location__c merchantLocation = new Merchant_Location__c(
            Name = 'Test Merchant Location',
            Address_1_text__c = '132 Waterloo Avenue',
            Parish_Province_State_list__c = 'Kingston',
            Country_list__c = 'Jamaica',
            Customer_Account_ID__c = testAccount.Id
        );
        insert merchantLocation;

        // Create test case
        Case testCase = new Case(
            Subject = 'Test Service Assignment',
            AccountId = testAccount.Id,
            Service_Territory__c = 'Kingston',
            Merchant_Location_Id__c = merchantLocation.Id
        );
        insert testCase;

        // Create terminal ID with Service_Territory_text__c
        Terminal_ID__c testTerminal = new Terminal_ID__c(
            Name = 'TEST001',
            Case__c = testCase.Id,
            Service_Territory_text__c = 'Kingston'
        );
        insert testTerminal;

        // Create SIM cards
        SerializedProduct simCard1 = new SerializedProduct(
            Product2Id = testProduct.Id,
            SerialNumber = 'SIM001',
            Substatus_list__c = 'Assigned to a Terminal ID',
            Terminal_ID_TID_Id__c = testTerminal.Id
        );
        insert simCard1;

        SerializedProduct simCard2 = new SerializedProduct(
            Product2Id = testProduct.Id,
            SerialNumber = 'SIM002',
            Substatus_list__c = 'Assigned to a Terminal ID',
            Terminal_ID_TID_Id__c = testTerminal.Id
        );
        insert simCard2;

        // Update terminal with SIM cards
        testTerminal.SIM_Card_Id__c = simCard1.Id;
        testTerminal.SIM_Card_2_Id__c = simCard2.Id;
        update testTerminal;

        // Create ProductItems for different locations
        ProductItem territoryProductItem = new ProductItem(
            LocationId = territoryLocation.Id,
            Product2Id = testProduct.Id,
            QuantityUnitOfMeasure = 'Each',
            QuantityOnHand = 0,
            Status__c = 'Available'
        );
        insert territoryProductItem;

        ProductItem hubProductItem = new ProductItem(
            LocationId = hubLocation.Id,
            Product2Id = testProduct.Id,
            QuantityUnitOfMeasure = 'Each',
            QuantityOnHand = 0,
            Status__c = 'Available'
        );
        insert hubProductItem;

        ProductItem kingstonProductItem = new ProductItem(
            LocationId = kingstonTerritoryLocation.Id,
            Product2Id = testProduct.Id,
            QuantityUnitOfMeasure = 'Each',
            QuantityOnHand = 0,
            Status__c = 'Available'
        );
        insert kingstonProductItem;

        // Create devices for territory shipment (available in "POS Devices for Territories")
        SerializedProduct territoryDevice = new SerializedProduct(
            Product2Id = testProduct.Id,
            SerialNumber = 'TER001',
            Status = 'Available',
            Substatus_list__c = 'Assigned to a Terminal ID',
            ProductItemId = territoryProductItem.Id,
            Terminal_ID_TID_Id__c = testTerminal.Id,
            Bank_Id__c = testAccount.Id
        );
        insert territoryDevice;

        // Create device for hub shipment
        SerializedProduct hubDevice = new SerializedProduct(
            Product2Id = testProduct.Id,
            SerialNumber = 'HUB001',
            Status = 'Available',
            Substatus_list__c = 'Assigned to a Terminal ID',
            ProductItemId = hubProductItem.Id,
            Terminal_ID_TID_Id__c = testTerminal.Id,
            Bank_Id__c = testAccount.Id
        );
        insert hubDevice;

        // Create shipped device (for testing getShippedPOSDevices)
        SerializedProduct shippedDevice = new SerializedProduct(
            Product2Id = testProduct.Id,
            SerialNumber = 'SHIP001',
            Status = 'Available',
            Substatus_list__c = 'Assigned to a Terminal ID',
            ProductItemId = territoryProductItem.Id,
            Terminal_ID_TID_Id__c = testTerminal.Id,
            Bank_Id__c = testAccount.Id
        );
        insert shippedDevice;

        // Create ProductTransfer for shipped device
        ProductTransfer shippedTransfer = new ProductTransfer(
            SourceProductItemId = territoryProductItem.Id,
            DestinationLocationId = kingstonTerritoryLocation.Id,
            Product2Id = testProduct.Id,
            QuantitySent = 1,
            QuantityUnitOfMeasure = 'Each',
            Status = 'Sent',
            IsReceived = false
        );
        insert shippedTransfer;

        // Create ProductTransferState for shipped device
        ProductTransferState shippedState = new ProductTransferState(
            ProductTransferId = shippedTransfer.Id,
            SerializedProductId = shippedDevice.Id,
            Action = 'Send',
            TransferState = 'Sent'
        );
        insert shippedState;

        shippedTransfer.IsSent = true;
        update shippedTransfer;

        // Create received device (for testing getReceivedShippedPOSDevices)
        SerializedProduct receivedDevice = new SerializedProduct(
            Product2Id = testProduct.Id,
            SerialNumber = 'REC001',
            Status = 'Available',
            Substatus_list__c = 'Assigned to a Terminal ID',
            ProductItemId = territoryProductItem.Id,
            Terminal_ID_TID_Id__c = testTerminal.Id,
            Bank_Id__c = testAccount.Id
        );
        insert receivedDevice;

        // Create ProductTransfer for received device
        ProductTransfer receivedTransfer = new ProductTransfer(
            SourceProductItemId = territoryProductItem.Id,
            DestinationLocationId = kingstonTerritoryLocation.Id,
            Product2Id = testProduct.Id,
            QuantitySent = 1,
            QuantityReceived = 1,
            QuantityUnitOfMeasure = 'Each',
            Status = 'Sent'
        );
        insert receivedTransfer;

        // Create ProductTransferState for shipped device
        ProductTransferState sendState = new ProductTransferState(
            ProductTransferId = receivedTransfer.Id,
            SerializedProductId = receivedDevice.Id,
            Action = 'Send',
            TransferState = 'Sent'
        );
        insert sendState;

        receivedTransfer.IsSent = true;
        update receivedTransfer;

        // Create ProductTransferState for received device
        ProductTransferState receivedState = new ProductTransferState(
            ProductTransferId = receivedTransfer.Id,
            SerializedProductId = receivedDevice.Id,
            Action = 'Receive',
            TransferState = 'Available'
        );
        insert receivedState;

        receivedTransfer.IsReceived = true;
        update receivedTransfer;
    }

    @isTest
    static void testGetPOSDevicesForShipmentTerritory() {
        Test.startTest();
        List<ShippedPOSDeviceWrapper> devices = ShippedPOSDevicesController.getPOSDevicesForShipment('Kingston', 'territory');
        Test.stopTest();

        System.assertNotEquals(null, devices, 'Devices list should not be null');
        System.assertEquals(1, devices.size(), 'Should return 1 device for territory shipment');
    }

    @isTest
    static void testGetPOSDevicesForShipmentHub() {
        Test.startTest();
        List<ShippedPOSDeviceWrapper> devices = ShippedPOSDevicesController.getPOSDevicesForShipment('Test Hub', 'hub');
        Test.stopTest();

        System.assertNotEquals(null, devices, 'Devices list should not be null');
        System.assertEquals(3, devices.size(), 'Should return 3 devices for hub shipment');
    }

    @isTest
    static void testGetShippedPOSDevicesTerritory() {
        User testUser = [SELECT Id FROM User WHERE Username = 'test.logistician@test.com.test' LIMIT 1];

        System.runAs(testUser) {
          Test.startTest();
          List<ShippedPOSDeviceWrapper> devices = ShippedPOSDevicesController.getShippedPOSDevices('Kingston', 'territory');
          Test.stopTest();

          System.assertNotEquals(null, devices, 'Devices list should not be null');
          
          if (devices.size() > 0) {
              ShippedPOSDeviceWrapper device = devices[0];
              System.assertEquals('SHIP001', device.serialNumber, 'Serial number should match');
              System.assertEquals(true, device.shipped, 'Shipped should be true');
              System.assertEquals(true, device.received, 'Received should be true by default');
              System.assertNotEquals(null, device.dateSent, 'Date sent should be populated');
          }
        }
    }

    @isTest
    static void testGetShippedPOSDevicesHub() {
        User testUser = [SELECT Id FROM User WHERE Username = 'test.logistician@test.com.test' LIMIT 1];

        System.runAs(testUser) {
            Test.startTest();
            List<ShippedPOSDeviceWrapper> devices = ShippedPOSDevicesController.getShippedPOSDevices('Test Hub', 'hub');
            Test.stopTest();

            System.assertNotEquals(null, devices, 'Devices list should not be null');
        }
    }

    @isTest
    static void testGetReceivedShippedPOSDevicesTerritory() {
        User testUser = [SELECT Id FROM User WHERE Username = 'test.logistician@test.com.test' LIMIT 1];

        System.runAs(testUser) {
            Test.startTest();
            List<ShippedPOSDeviceWrapper> devices = ShippedPOSDevicesController.getReceivedShippedPOSDevices('Kingston', 'territory');
            Test.stopTest();

            System.assertNotEquals(null, devices, 'Devices list should not be null');
            
            if (devices.size() > 0) {
                ShippedPOSDeviceWrapper device = devices[0];
                System.assertEquals('REC001', device.serialNumber, 'Serial number should match');
                System.assertEquals(false, device.reship, 'Reship should be false by default');
                System.assertEquals('', device.reshipDestination, 'Reship destination should be empty');
                System.assertNotEquals(null, device.dateReceived, 'Date received should be populated');
            }
        }
    }

    @isTest
    static void testGetReceivedShippedPOSDevicesHub() {
        User testUser = [SELECT Id FROM User WHERE Username = 'test.logistician@test.com.test' LIMIT 1];

        System.runAs(testUser) {
            Test.startTest();
            List<ShippedPOSDeviceWrapper> devices = ShippedPOSDevicesController.getReceivedShippedPOSDevices('Test Hub', 'hub');
            Test.stopTest();

            System.assertNotEquals(null, devices, 'Devices list should not be null');
        }
    }

    @isTest
    static void testSearchPOSDevicesForShipment() {
        Test.startTest();
        List<ShippedPOSDeviceWrapper> devices = ShippedPOSDevicesController.searchPOSDevices('TER', 'devices-for-shipment', 'Kingston', 'territory');
        Test.stopTest();

        System.assertNotEquals(null, devices, 'Search results should not be null');
        System.assertEquals(1, devices.size(), 'Search should return 1 device');
        System.assertEquals('TER001', devices[0].serialNumber, 'Should find device with TER serial number');
    }

    @isTest
    static void testSearchPOSDevicesShipped() {
        Test.startTest();
        List<ShippedPOSDeviceWrapper> devices = ShippedPOSDevicesController.searchPOSDevices('SHIP', 'shipped-devices', 'Kingston', 'territory');
        Test.stopTest();

        System.assertNotEquals(null, devices, 'Search results should not be null');
    }

    @isTest
    static void testSearchPOSDevicesReceived() {
        Test.startTest();
        List<ShippedPOSDeviceWrapper> devices = ShippedPOSDevicesController.searchPOSDevices('REC', 'received-shipped-devices', 'Kingston', 'territory');
        Test.stopTest();

        System.assertNotEquals(null, devices, 'Search results should not be null');
    }

    @isTest
    static void testSearchPOSDevicesEmptyTerm() {
        Test.startTest();
        List<ShippedPOSDeviceWrapper> devices = ShippedPOSDevicesController.searchPOSDevices('', 'devices-for-shipment', 'Kingston', 'territory');
        Test.stopTest();

        System.assertNotEquals(null, devices, 'Search results should not be null');
        // Should return all devices when search term is empty
    }

    @isTest
    static void testConfirmShipmentTerritory() {
        // Get the territory device to ship
        SerializedProduct territoryDevice = [SELECT Id FROM SerializedProduct WHERE SerialNumber = 'TER001' LIMIT 1];

        // Count existing transfers before test
        Integer initialTransferCount = [SELECT COUNT() FROM ProductTransfer];

        Test.startTest();
        ShippedPOSDevicesController.confirmShipment(new List<String>{territoryDevice.Id}, 'Kingston', 'territory');
        Test.stopTest();

        // Verify new ProductTransfer was created
        List<ProductTransfer> allTransfers = [
            SELECT Id, Status, IsReceived
            FROM ProductTransfer
            ORDER BY CreatedDate DESC
        ];
        System.assertEquals(initialTransferCount + 1, allTransfers.size(), 'New ProductTransfer should be created');
        
        ProductTransfer newTransfer = allTransfers[0]; // Most recent transfer
        System.assertEquals('Sent', newTransfer.Status, 'Transfer status should be Sent');
        System.assertEquals(false, newTransfer.IsReceived, 'Transfer should not be received');

        // Verify ProductTransferState was created
        List<ProductTransferState> states = [
            SELECT Id, Action, TransferState
            FROM ProductTransferState
            WHERE ProductTransferId = :newTransfer.Id
            AND Action = 'Send'
        ];
        System.assertEquals(1, states.size(), 'ProductTransferState should be created');
        System.assertEquals('Send', states[0].Action, 'Action should be Send');
        System.assertEquals('Sent', states[0].TransferState, 'TransferState should be Sent');
    }

    @isTest
    static void testConfirmShipmentHub() {
        // Get the hub device to ship
        SerializedProduct hubDevice = [SELECT Id FROM SerializedProduct WHERE SerialNumber = 'HUB001' LIMIT 1];

        // Count existing transfers before test
        Integer initialTransferCount = [SELECT COUNT() FROM ProductTransfer];

        Test.startTest();
        ShippedPOSDevicesController.confirmShipment(new List<String>{hubDevice.Id}, 'Test Hub', 'hub');
        Test.stopTest();

        // Verify ProductTransfer was created for hub shipment
        List<ProductTransfer> allTransfers = [
            SELECT Id, Status
            FROM ProductTransfer
            ORDER BY CreatedDate DESC
        ];
        System.assertEquals(initialTransferCount + 1, allTransfers.size(), 'New ProductTransfer should be created for hub shipment');
    }

    @isTest
    static void testConfirmReceipt() {
        // Get the shipped device to receive
        SerializedProduct shippedDevice = [SELECT Id, ProductItemId FROM SerializedProduct WHERE SerialNumber = 'SHIP001' LIMIT 1];

        Test.startTest();
        ShippedPOSDevicesController.confirmReceipt(new List<String>{shippedDevice.Id}, 'Kingston', 'territory');
        Test.stopTest();

        // Verify ProductTransfer was updated to Received
        // Get the ProductTransfer that was set up in the test data for the shipped device
        ProductTransfer updatedTransfer = [
            SELECT Id, Status, IsReceived, QuantityReceived
            FROM ProductTransfer
            WHERE Status = 'Received'
            AND IsReceived = true
            ORDER BY LastModifiedDate DESC
            LIMIT 1
        ];
        System.assertEquals('Received', updatedTransfer.Status, 'Transfer status should be Received');
        System.assertEquals(true, updatedTransfer.IsReceived, 'Transfer should be marked as received');
        System.assertEquals(1, updatedTransfer.QuantityReceived, 'Quantity received should be 1');

        // Verify new ProductTransferState was created for receipt
        List<ProductTransferState> receiptStates = [
            SELECT Id, Action, TransferState
            FROM ProductTransferState
            WHERE ProductTransferId = :updatedTransfer.Id
            AND Action = 'Receive'
        ];
        System.assertEquals(1, receiptStates.size(), 'Receipt ProductTransferState should be created');
        System.assertEquals('Available', receiptStates[0].TransferState, 'TransferState should be Available');
    }
}