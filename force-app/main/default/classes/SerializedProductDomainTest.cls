@isTest
public class SerializedProductDomainTest {

    @isTest
    static void testChangeProgrammedDeviceLocation() {
        // Setup test data
        System.debug('testChangeProgrammedDeviceLocation = ');

        Account chiefOfficeJn = createAccount('JN Bank Chief Office', 'JMD', false);
        chiefOfficeJn.Parish__c = 'Kingston';
        insert chiefOfficeJn;

        System.debug('chiefOfficeJn = ' + chiefOfficeJn);
        
        Schema.Location loc1 = new Schema.Location(Name='Loc1', Customer_Name_Id__c=chiefOfficeJn.Id, LocationType='Programmed devices', IsInventoryLocation=true);
        insert loc1;

        System.debug('loc1 = ' + loc1);

        Product2 prod1 = new Product2(Name='Product1', IsActive=true, IsSerialized=true);
        insert prod1;

        System.debug('prod1 = ' + prod1);

        SerializedProduct sp1 = new SerializedProduct(Product2Id=prod1.Id, Bank_Id__c=chiefOfficeJn.Id, SerialNumber='112313');
        insert sp1;

        System.debug('sp1 = ' + sp1);

        // Change Substatus_list__c to 'Assigned to a Terminal ID'
        sp1.Substatus_list__c = 'Assigned to a Terminal ID';
        update sp1;
        System.debug('sp1 = ' + sp1);

        // Prepare oldMap
        Map<Id, SerializedProduct> oldMap = new Map<Id, SerializedProduct>();
        oldMap.put(sp1.Id, [SELECT Id, Substatus_list__c FROM SerializedProduct WHERE Id = :sp1.Id]);

        // Test method
        Test.startTest();
        System.debug('TEST');

        SerializedProductDomain.changeProgrammedDeviceLocation(new List<SerializedProduct>{sp1}, oldMap);
        Test.stopTest();

        // Verify results
        SerializedProduct updatedSP = [SELECT Id, ProductItemId FROM SerializedProduct WHERE Id = :sp1.Id];
        System.debug('updatedSP = ' + updatedSP);

        System.assertNotEquals(null, updatedSP.ProductItemId, 'ProductItemId should be set');
    }

    @isTest
    static void testChangeUnprogrammedDeviceLocation() {
        // Setup test data
        Schema.Location loc1 = new Schema.Location(Name='Loc1', Customer_Name_Id__c='Customer1', LocationType='Unprogrammed devices', IsInventoryLocation=true);
        insert loc1;

        Product2 prod1 = new Product2(Name='Product1');
        insert prod1;

        SerializedProduct sp1 = new SerializedProduct(Product2Id=prod1.Id, Bank_Id__c='Customer1', Substatus_list__c='Assigned to a Terminal ID');
        insert sp1;

        // Change Substatus_list__c to 'Not Assigned'
        sp1.Substatus_list__c = 'Not Assigned';
        update sp1;

        // Prepare oldMap
        Map<Id, SerializedProduct> oldMap = new Map<Id, SerializedProduct>();
        oldMap.put(sp1.Id, [SELECT Id, Substatus_list__c FROM SerializedProduct WHERE Id = :sp1.Id]);

        // Test method
        Test.startTest();
        SerializedProductDomain.changeUnprogrammedDeviceLocation(new List<SerializedProduct>{sp1}, oldMap);
        Test.stopTest();

        // Verify results
        SerializedProduct updatedSP = [SELECT Id, ProductItemId FROM SerializedProduct WHERE Id = :sp1.Id];
        System.assertNotEquals(null, updatedSP.ProductItemId, 'ProductItemId should be set');
    }

    @isTest
    static void testChangePickedUpDeviceLocation() {
        // Setup test data
        Schema.Location loc1 = new Schema.Location(Name='Technician1', LocationType='Technician', IsInventoryLocation=true);
        insert loc1;

        Product2 prod1 = new Product2(Name='Product1');
        insert prod1;

        SerializedProduct sp1 = new SerializedProduct(Product2Id=prod1.Id, Bank_Id__c='Technician1', Picked_Up__c=false);
        insert sp1;

        // Change Picked_Up__c to true
        sp1.Picked_Up__c = true;
        update sp1;

        // Prepare oldMap
        Map<Id, SerializedProduct> oldMap = new Map<Id, SerializedProduct>();
        oldMap.put(sp1.Id, [SELECT Id, Picked_Up__c FROM SerializedProduct WHERE Id = :sp1.Id]);

        // Test method
        Test.startTest();
        SerializedProductDomain.changePickedUpDeviceLocation(new List<SerializedProduct>{sp1}, oldMap);
        Test.stopTest();

        // Verify results
        SerializedProduct updatedSP = [SELECT Id, ProductItemId FROM SerializedProduct WHERE Id = :sp1.Id];
        System.assertNotEquals(null, updatedSP.ProductItemId, 'ProductItemId should be set');
    }

    @isTest
    static void testChangeReturnedDeviceLocation() {
        // Setup test data
        Schema.Location loc1 = new Schema.Location(Name='Warehouse1', Customer_Name_Id__c='Customer1', LocationType='Warehouse', IsInventoryLocation=true);
        insert loc1;

        Product2 prod1 = new Product2(Name='Product1');
        insert prod1;

        SerializedProduct sp1 = new SerializedProduct(Product2Id=prod1.Id, Bank_Id__c='Customer1', Returned__c=false);
        insert sp1;

        sp1.Returned__c = true;
        update sp1;

        // Prepare oldMap
        Map<Id, SerializedProduct> oldMap = new Map<Id, SerializedProduct>();
        oldMap.put(sp1.Id, [SELECT Id, Returned__c FROM SerializedProduct WHERE Id = :sp1.Id]);

        // Test method
        Test.startTest();
        SerializedProductDomain.changeReturnedDeviceLocation(new List<SerializedProduct>{sp1}, oldMap);
        Test.stopTest();

        // Verify results
        SerializedProduct updatedSP = [SELECT Id, ProductItemId FROM SerializedProduct WHERE Id = :sp1.Id];
        System.assertNotEquals(null, updatedSP.ProductItemId, 'ProductItemId should be set');
    }

    @isTest
    static void testCreateProductItem() {
        // Setup test data
        Schema.Location loc1 = new Schema.Location(Name='Warehouse1', Customer_Name_Id__c='Customer1', LocationType='Warehouse', IsInventoryLocation=true);
        insert loc1;

        Product2 prod1 = new Product2(Name='Product1');
        insert prod1;

        SerializedProduct sp1 = new SerializedProduct(Product2Id=prod1.Id, Bank_Id__c='Customer1', Destination_Location_Id__c=loc1.Id);
        insert sp1;

        // Test method
        Test.startTest();
        ProductItem productItem = SerializedProductDomain.createProductItem(sp1, loc1);
        insert productItem;
        Test.stopTest();

        // Verify results
        ProductItem pi = [SELECT Id, LocationId, Product2Id FROM ProductItem WHERE Id = :productItem.Id];
        System.assertNotEquals(null, pi, 'ProductItem should be created');
        System.assertEquals(loc1.Id, pi.LocationId, 'LocationId should be set correctly');
        System.assertEquals(prod1.Id, pi.Product2Id, 'Product2Id should be set correctly');
    }

    public static Account createAccount(String accName, String currencyCode, Boolean isInsert ) {
        Account account = new Account(
            Name = accName,
            CurrencyIsoCode = currencyCode,
            Parish__c = 'St. Mary',
            Country__c = 'Jamaica');
        if (isInsert) {
            insert account;
        }
        return account;
    }
    
}