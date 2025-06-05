/**
 * @description       : 
 * @author            : Remario Richards
 * @group             : 
 * @last modified on  : 01-02-2024
 * @last modified by  : Remario Richards
**/
@isTest
public with sharing class DeviceControllerTest {
    @isTest
    static void testGetRelatedAssets() {
        // Create test data
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Asset testAsset = new Asset(
            Name = 'Test Asset',
            AccountId = testAccount.Id
        );
        insert testAsset;

        // Call the method
        List<Id> accountIds = new List<Id>{testAsset.Id};
        List<AssetWrapper> result = DeviceController.getRelatedAssets(accountIds);

        // Assert the result
        System.assertEquals(1, result.size(), 'Expected one AssetWrapper in the result');

        AssetWrapper assetWrapper = result[0];
        System.assertEquals(testAsset.Id, assetWrapper.id, 'Asset Id should match');
        System.assertEquals(testAsset.Name, assetWrapper.name, 'Asset Name should match');

    }
    @isTest
    static void testFindRecords() {
        // Create test data
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        // Call the method
        String objectName = 'Account';
        String value = 'Test';
        List<sObject> result = DeviceController.findRecords(objectName, value);

        // Assert the result
        System.assertNotEquals(null, result, 'Result should not be null');

        // Since we are querying for Account records, we can assume the result is a list of Account sObjects
        // Adjust this assertion based on the specific object you are querying
        System.assertNotEquals(0, result.size(), 'Expected size is not 0 because test data was inserted');
    }
    @isTest
    static void testGetReturnOrderLineItems() {
        List<String> recordIds = new List<String>{null};
        List<ReturnOrderLineItemWrapper> results = DeviceController.getReturnOrderLineItems(recordIds);
        Assert.areEqual(0,results.size(),'Expected 0 return order line');
        ReturnOrderLineItem record = new ReturnOrderLineItem(Id= null,Work_Order_Id__c = null, Status_list__c = null);
        ReturnOrderLineItemWrapper wrapper = new ReturnOrderLineItemWrapper(record);
        Assert.isNotNull(wrapper, 'wrapper should not be null');
    }

    @isTest
    static void testUpdateRecordsToCreateProductConsumption() {
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        WorkOrder testWorkOrder = new WorkOrder(AccountId = testAccount.Id);
        insert testWorkOrder;

        Product2 testProduct = new Product2(
            Name = 'Test POS Device',
            IsActive = true,
            IsSerialized = true
        );
        insert testProduct;

        Schema.Location testLocation = new Schema.Location(
            Name = 'Test Location',
            LocationType = 'Programmer',
            IsInventoryLocation = true
        );
        insert testLocation;

        ProductItem testProductItem = new ProductItem(
            Product2Id = testProduct.Id,
            LocationId = testLocation.Id,
            QuantityUnitOfMeasure = 'Each',
            QuantityOnHand = 0,
            Status__c = 'Available'
        );
        insert testProductItem;

        SerializedProduct testSerializedProduct = new SerializedProduct(Installed__c = true, Picked_Up__c = true, Product2Id = testProduct.Id, SerialNumber = '1234567890', ProductItemId = testProductItem.Id);
        insert testSerializedProduct;

        Terminal_ID__c testTerminalId = new Terminal_ID__c(Work_Order_Id__c = testWorkOrder.Id, POS_Id__c = testSerializedProduct.Id);
        insert testTerminalId;

        WorkOrderLineItem testWorkOrderLineItem = new WorkOrderLineItem(WorkOrderId = testWorkOrder.Id);
        insert testWorkOrderLineItem;

        List<ReturnDeviceWrapper> returnDeviceList = new List<ReturnDeviceWrapper>();
        ReturnDeviceWrapper returnDevice = new ReturnDeviceWrapper();
        returnDevice.id = testTerminalId.Id;
        returnDevice.workOrderId = testWorkOrder.Id;
        returnDevice.workOrderLineItemId = testWorkOrderLineItem.Id;
        returnDevice.serializedProduct = testSerializedProduct.Id;
        returnDevice.installed = true;
        returnDevice.reason = 'Test Reason';
        returnDevice.createProductConsumption = true;
        returnDevice.deleteProductConsumption = false;
        returnDeviceList.add(returnDevice);

        Test.startTest();
        DeviceController.updateRecords(JSON.serialize(returnDeviceList), testWorkOrderLineItem.Id);
        Test.stopTest();

        List<ProductConsumed> productConsumedList = [SELECT Id, WorkOrderId, WorkOrderLineItemId, ProductItemId, Serialized_Product_ID__c, QuantityConsumed FROM ProductConsumed WHERE WorkOrderLineItemId = :testWorkOrderLineItem.Id];
        Assert.areEqual(1, productConsumedList.size(), 'Expected 1 product consumed');
        Assert.areEqual(testWorkOrderLineItem.Id, productConsumedList[0].WorkOrderLineItemId, 'Expected work order line item id to match');
        Assert.areEqual(testSerializedProduct.Id, productConsumedList[0].Serialized_Product_ID__c, 'Expected serialized product id to match');
    }

    @isTest 
    static void testGetTerminalIds() {
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        WorkOrder testWorkOrder = new WorkOrder(AccountId = testAccount.Id);
        insert testWorkOrder;

        Product2 testProduct = new Product2(
            Name = 'Test POS Device',
            IsActive = true,
            IsSerialized = true
        );
        insert testProduct;

        SerializedProduct testSerializedProduct = new SerializedProduct(Installed__c = true, Picked_Up__c = true, Product2Id = testProduct.Id, SerialNumber = '1234567890');
        insert testSerializedProduct;

        Terminal_ID__c testTerminalId = new Terminal_ID__c(Work_Order_Id__c = testWorkOrder.Id, POS_Id__c = testSerializedProduct.Id);
        insert testTerminalId;

        WorkOrderLineItem testWorkOrderLineItem = new WorkOrderLineItem(WorkOrderId = testWorkOrder.Id);
        insert testWorkOrderLineItem;

        Test.startTest();
        List<ReturnDeviceWrapper> results = DeviceController.getTerminalIds(new List<String>{testWorkOrderLineItem.Id});
        Test.stopTest();

        Assert.areEqual(1,results.size(),'Expected 1 terminal id');
    }
}