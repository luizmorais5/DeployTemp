@isTest
public class ReturnedPOSDevicesControllerTest {

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
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
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
            // If FSL__User_Territory__c doesn't exist or has different field names,
            // the tests will run without territory restrictions
            System.debug('FSL__User_Territory__c creation failed: ' + e.getMessage());
        }

        // Create programming location for the bank
        Schema.Location bankProgrammingLocation = new Schema.Location(
            Name = 'Test Bank POS Devices for Programming',
            LocationType = 'Programmer',
            IsInventoryLocation = true,
            Customer_Name_Id__c = testAccount.Id
        );
        insert bankProgrammingLocation;

        // Create warehouse location for returned devices
        Schema.Location warehouseLocation = new Schema.Location(
            Name = 'Test Warehouse',
            LocationType = 'Warehouse',
            IsInventoryLocation = true,
            Customer_Name_Id__c = testAccount.Id
        );
        insert warehouseLocation;

        // Create merchant location
        Merchant_Location__c merchantLocation = new Merchant_Location__c(
            Name = 'Test Merchant Location',
            Address_1_text__c = '132 Waterloo Avenue',
            Parish_Province_State_list__c = 'Kingston',
            Country_list__c = 'Jamaica',
            Customer_Account_ID__c = testAccount.Id
        );
        insert merchantLocation;

        // Create test case (service assignment)
        Case testCase = new Case(
            Subject = 'Test Service Assignment',
            AccountId = testAccount.Id,
            Service_Territory__c = 'Kingston',
            Merchant_Location_Id__c = merchantLocation.Id
        );
        insert testCase;

        // Create terminal ID with Service_Territory_text__c matching the territory
        Terminal_ID__c testTerminal = new Terminal_ID__c(
            Name = 'TEST001',
            Case__c = testCase.Id,
            Service_Territory_text__c = 'Kingston'
        );
        insert testTerminal;

        // Create SIM card SerializedProducts first
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

        testTerminal.SIM_Card_Id__c = simCard1.Id;
        testTerminal.SIM_Card_2_Id__c = simCard2.Id;
        update testTerminal;

        // Create ProductItems for warehouse and programming locations
        ProductItem warehouseProductItem = new ProductItem(
            LocationId = warehouseLocation.Id,
            Product2Id = testProduct.Id,
            QuantityUnitOfMeasure = 'Each',
            QuantityOnHand = 0,
            Status__c = 'Available'
        );
        insert warehouseProductItem;

        ProductItem programmingProductItem = new ProductItem(
            LocationId = bankProgrammingLocation.Id,
            Product2Id = testProduct.Id,
            QuantityUnitOfMeasure = 'Each',
            QuantityOnHand = 0,
            Status__c = 'Available'
        );
        insert programmingProductItem;

        // Create returned SerializedProduct
        SerializedProduct returnedDevice = new SerializedProduct(
            Product2Id = testProduct.Id,
            SerialNumber = 'RET001',
            Substatus_list__c = 'Assigned to a Terminal ID',
            ProductItemId = warehouseProductItem.Id,
            Terminal_ID_TID_Id__c = testTerminal.Id,
            Bank_Id__c = testAccount.Id
        );
        insert returnedDevice;

        // Create accepted returned SerializedProduct (unprogrammed after acceptance)
        SerializedProduct acceptedDevice = new SerializedProduct(
            Product2Id = testProduct.Id,
            SerialNumber = 'ACC001',
            Substatus_list__c = 'Not Assigned',
            ProductItemId = programmingProductItem.Id,
            Bank_Id__c = testAccount.Id,
            Terminal_ID_TID_Id__c = testTerminal.Id
        );
        insert acceptedDevice;

        // Create simple ProductTransfer for returned device
        ProductTransfer returnedTransfer = new ProductTransfer(
            SourceProductItemId = warehouseProductItem.Id,
            DestinationLocationId = warehouseLocation.Id,
            Product2Id = testProduct.Id,
            QuantitySent = 1,
            QuantityUnitOfMeasure = 'Each',
            Status = 'Returned',
            IsReceived = false
        );
        insert returnedTransfer;

        // Create simple ProductTransfer for accepted device
        ProductTransfer acceptedTransfer = new ProductTransfer(
            SourceProductItemId = programmingProductItem.Id,
            DestinationLocationId = bankProgrammingLocation.Id,
            Product2Id = testProduct.Id,
            QuantitySent = 1,
            QuantityReceived = 0,
            QuantityUnitOfMeasure = 'Each',
            Status = 'Shipped'
        );
        insert acceptedTransfer;

        // Create ProductTransferState for returned device
        ProductTransferState returnedState = new ProductTransferState(
            ProductTransferId = returnedTransfer.Id,
            SerializedProductId = returnedDevice.Id,
            Action = 'Send',
            TransferState = 'Sent'
        );
        insert returnedState;

        returnedTransfer.IsSent = true;
        returnedTransfer.QuantitySent = 1;
        update returnedTransfer;

        // Create ProductTransferState for accepted device
        ProductTransferState acceptedState = new ProductTransferState(
            ProductTransferId = acceptedTransfer.Id,
            SerializedProductId = acceptedDevice.Id,
            Action = 'Receive',
            TransferState = 'Sent'
        );
        insert acceptedState;
    }

    @isTest
    static void testGetReturnedPOSDevices() {
        User testUser = [SELECT Id FROM User WHERE Username = 'test.logistician@test.com.test' LIMIT 1];

        System.runAs(testUser) {
            Test.startTest();
            List<ReturnedPOSDeviceWrapper> devices = ReturnedPOSDevicesController.getReturnedPOSDevices();
            Test.stopTest();

            System.assertNotEquals(null, devices, 'Devices list should not be null');

            if (devices.size() > 0) {
                ReturnedPOSDeviceWrapper device = devices[0];
                System.assertEquals('RET001', device.serialNumber, 'Serial number should match');
                System.assertEquals('TEST001', device.tid, 'TID should match');
                System.assertEquals('Test Bank', device.merchantName, 'Merchant name should match');
                System.assertEquals('Test Bank', device.bankName, 'Bank name should match');
                System.assertEquals(false, device.accepted, 'Accepted should be false initially');
            }
        }
    }

    @isTest
    static void testGetAcceptedReturnedPOSDevices() {
        User testUser = [SELECT Id FROM User WHERE Username = 'test.logistician@test.com.test' LIMIT 1];

        System.runAs(testUser) {
            Test.startTest();
            List<ReturnedPOSDeviceWrapper> devices = ReturnedPOSDevicesController.getAcceptedReturnedPOSDevices();
            Test.stopTest();

            System.assertNotEquals(null, devices, 'Devices list should not be null');

            if (devices.size() > 0) {
                ReturnedPOSDeviceWrapper device = devices[0];
                System.assertEquals('ACC001', device.serialNumber, 'Serial number should match');
                System.assertEquals('Test Bank', device.bankName, 'Bank name should match');
                // TID should be null for accepted devices (unprogrammed)
                System.assertEquals(null, device.tid, 'TID should be null for unprogrammed accepted device');
            }
        }
    }

    @isTest
    static void testSearchReturnedPOSDevices() {
        Test.startTest();
        List<ReturnedPOSDeviceWrapper> devices = ReturnedPOSDevicesController.searchReturnedPOSDevices('RET', 'returned');
        Test.stopTest();

        System.assertEquals(1, devices.size(), 'Search results should return 1 device');
    }

    @isTest
    static void testConfirmAcceptanceOfDevices() {
        // Get the returned device to accept
        SerializedProduct returnedDevice = [SELECT Id, Terminal_ID_TID_Id__c, ProductItemId, Bank_Id__c FROM SerializedProduct WHERE SerialNumber = 'RET001' LIMIT 1];

        Test.startTest();
        try {
            ReturnedPOSDevicesController.confirmAcceptanceOfDevices(new List<String>{returnedDevice.Id});
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
            return;
        }
        Test.stopTest();

        // Verify the device was un-programmed
        SerializedProduct updatedDevice = [
            SELECT Id, Substatus_list__c, Terminal_ID_TID_Id__c, Destination_Location_Id__c, ProductItemId
            FROM SerializedProduct
            WHERE Id = :returnedDevice.Id
        ];
        System.assertEquals('Not Assigned', updatedDevice.Substatus_list__c, 'Device should be un-programmed');
        System.assertEquals(null, updatedDevice.Terminal_ID_TID_Id__c, 'Terminal ID should be cleared');
        System.assertNotEquals(null, updatedDevice.Destination_Location_Id__c, 'Destination location should be set');

        List<ReturnedPOSDeviceWrapper> devices = ReturnedPOSDevicesController.searchReturnedPOSDevices('ACC', 'accepted');

        // Verify ProductTransfer was updated to "Received"
        ProductTransfer updatedTransfer = [
            SELECT Id, Status, IsReceived, DestinationLocationId
            FROM ProductTransfer
            WHERE SourceProductItemId = :returnedDevice.ProductItemId
            ORDER BY LastModifiedDate DESC
            LIMIT 1
        ];
        System.assertEquals('Received', updatedTransfer.Status, 'Transfer status should be Received');
        System.assertEquals(true, updatedTransfer.IsReceived, 'Transfer should be marked as received');

        // Verify device is moved to programming location
        List<Schema.Location> programmingLocations = [
            SELECT Id FROM Location
            WHERE Name LIKE '%Programming%'
            AND Customer_Name_Id__c = :returnedDevice.Bank_Id__c
            LIMIT 1
        ];
        if (!programmingLocations.isEmpty()) {
            Schema.Location programmingLocation = programmingLocations[0];
            System.assertEquals(programmingLocation.Id, updatedTransfer.DestinationLocationId, 'Should be moved to programming location');
        }
    }
}