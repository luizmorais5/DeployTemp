public class SerializedProductDomain {
    
    public static void changeProgrammedDeviceLocation(List<SerializedProduct> lstSerializedProduct, Map<Id, SerializedProduct> oldMap){
        List<SerializedProduct> lstSerializedProductProcess = new List<SerializedProduct>();
        for (SerializedProduct seralizedProduct : lstSerializedProduct) {
            SerializedProduct oldSerializedProduct = oldMap.get(seralizedProduct.Id);
            
            if (seralizedProduct.Substatus_list__c != oldSerializedProduct.Substatus_list__c 
                && seralizedProduct.Substatus_list__c == 'Assigned to a Terminal ID') {
                lstSerializedProductProcess.add(seralizedProduct);
            }
        }

        if(!lstSerializedProductProcess.isEmpty()){
            changeProgrammedDeviceLocation(lstSerializedProductProcess);
        }
    }

    public static void changeProgrammedDeviceLocation(List<SerializedProduct> lstSerializedProduct){
        Set<Id> setCustomerId = new Set<Id>();
        Set<Id> setProductId = new Set<Id>();
        List<ProductItem> lstProductItemInsert = new List<ProductItem>();
        List<SerializedProduct> lstSerializedProductUpdate = new List<SerializedProduct>();
        Map<Id, Schema.Location> mapLocationByCustomer = new Map<Id, Schema.Location>();
        Map<String, ProductItem> mapProductItemByLocation = new Map<String, ProductItem>();
        Map<String, ProductItem> mapNewProductItemByKey = new Map<String, ProductItem>();

        for(SerializedProduct serializedProduct : lstSerializedProduct){
            setCustomerId.add(serializedProduct.Bank_Id__c);
            setProductId.add(serializedProduct.Product2Id);
        }

        //get new Location by Customer
        for(Schema.Location loc : [SELECT Id, Name, Customer_Name_Id__c FROM Location WHERE Customer_Name_Id__c IN: setCustomerId AND LocationType = 'Programmed devices']){
            mapLocationByCustomer.put(loc.Customer_Name_Id__c, loc);
        }

        //get ProductItem From Location
        for(ProductItem productItem : [SELECT Id, LocationId, Product2Id FROM ProductItem WHERE LocationId IN: mapLocationByCustomer.values() AND Product2Id IN: setProductId]){
            String key = productItem.LocationId + '-' + productItem.Product2Id;
            mapProductItemByLocation.put(key, productItem);
        }

        Map<Id, ProductItem> productItemByProductId = new Map<Id, ProductItem>();

        for(ProductItem productItem : [SELECT Id, Location.LocationType, Product2Id FROM ProductItem WHERE Product2Id IN: setProductId]){
            productItemByProductId.put(productItem.Product2Id, productItem);
        }

        //set ProductItem Location
        for (SerializedProduct serializedProduct : lstSerializedProduct) {
            Schema.Location loc = mapLocationByCustomer.get(serializedProduct.Bank_Id__c);

            if(loc == null){
                continue;
            }

            String key = loc.Id + '-' + serializedProduct.Product2Id;
            serializedProduct.Destination_Location_Id__c = loc.Id;

            ProductItem productItem = mapProductItemByLocation.get(key);

            if(productItem != null){
                ProductItem existingProductItem = productItemByProductId.get(serializedProduct.Product2Id);

                // Task 139686 - Prevent automatic transfer of product item from unprogrammed devices to programmed devices
                if(existingProductItem != null && existingProductItem.Location != null && existingProductItem.Location.LocationType == 'Unprogrammed devices'){
                    continue;
                }

                serializedProduct.ProductItemId = productItem.Id;
            } else if(productItem == null){
                //Create Product Item in current Location
                productItem = new ProductItem();
                productItem = createProductItem(serializedProduct, loc);

                lstProductItemInsert.add(productItem);
                mapNewProductItemByKey.put(key, productItem);
            }
        }

        if(!lstProductItemInsert.isEmpty()){
            insert lstProductItemInsert;

            for(SerializedProduct serializedProduct : lstSerializedProductUpdate){
                Schema.Location loc = mapLocationByCustomer.get(serializedProduct.Bank_Id__c);
                String key = loc.Id + '-' + serializedProduct.Product2Id;
    
                ProductItem productItem = mapNewProductItemByKey.get(key);
                serializedProduct.ProductItemId = productItem.Id;
            }
        }
    }

    public static void changeUnprogrammedDeviceLocation(List<SerializedProduct> lstSerializedProduct, Map<Id, SerializedProduct> oldMap){
        List<SerializedProduct> lstSerializedProductProcess = new List<SerializedProduct>();
        for (SerializedProduct seralizedProduct : lstSerializedProduct) {
            SerializedProduct oldSerializedProduct = oldMap.get(seralizedProduct.Id);
            
            if (seralizedProduct.Substatus_list__c != oldSerializedProduct.Substatus_list__c 
                && seralizedProduct.Substatus_list__c == 'Not Assigned') {
                lstSerializedProductProcess.add(seralizedProduct);
            }
        }

        if(!lstSerializedProductProcess.isEmpty()){
            changeUnprogrammedDeviceLocation(lstSerializedProductProcess);
        }
    }

    public static void changeUnprogrammedDeviceLocation(List<SerializedProduct> lstSerializedProduct){
        Set<Id> setCustomerId = new Set<Id>();
        Set<Id> setProductId = new Set<Id>();
        List<ProductItem> lstProductItemInsert = new List<ProductItem>();
        List<SerializedProduct> lstSerializedProductUpdate = new List<SerializedProduct>();
        Map<Id, Schema.Location> mapLocationByCustomer = new Map<Id, Schema.Location>();
        Map<String, ProductItem> mapProductItemByLocation = new Map<String, ProductItem>();
        Map<Id, ProductItem> mapOldProductItemById = new Map<Id, ProductItem>();
        Map<String, ProductItem> mapNewProductItemByKey = new Map<String, ProductItem>();

        for(SerializedProduct serializedProduct : lstSerializedProduct){
            setCustomerId.add(serializedProduct.Bank_Id__c);
            setProductId.add(serializedProduct.Product2Id);
        }
        
        //get new Location by Customer
        for(Schema.Location loc : [SELECT Id, Name, Customer_Name_Id__c FROM Location WHERE Customer_Name_Id__c IN: setCustomerId AND LocationType = 'Unprogrammed devices']){
            mapLocationByCustomer.put(loc.Customer_Name_Id__c, loc);
        }

        //get ProductItem From Location
        for(ProductItem productItem : [SELECT Id, LocationId, Product2Id FROM ProductItem WHERE LocationId IN: mapLocationByCustomer.values() AND Product2Id IN: setProductId]){
            String key = productItem.LocationId + '-' + productItem.Product2Id;
            mapProductItemByLocation.put(key, productItem);
        }


        //set ProductItem Location
        for (SerializedProduct serializedProduct : lstSerializedProduct) {
            Schema.Location loc = mapLocationByCustomer.get(serializedProduct.Bank_Id__c);

            if(loc == null){
                continue;
            }

            String key = loc.Id + '-' + serializedProduct.Product2Id;
            serializedProduct.Destination_Location_Id__c = loc.Id;

            ProductItem productItem = new ProductItem();
            productItem = mapProductItemByLocation.get(key);
            if(loc != null && productItem != null){
                serializedProduct.ProductItemId = productItem.Id;
                lstSerializedProductUpdate.add(serializedProduct);
            } else if(productItem == null){
                //Create Product Item in current Location
                productItem = new ProductItem();
                productItem = createProductItem(serializedProduct, loc);

                lstProductItemInsert.add(productItem);
                mapNewProductItemByKey.put(key, productItem);
            }
        }

        if(!lstProductItemInsert.isEmpty()){
            insert lstProductItemInsert;

            for(SerializedProduct serializedProduct : lstSerializedProductUpdate){
                Schema.Location loc = mapLocationByCustomer.get(serializedProduct.Bank_Id__c);
                String key = loc.Id + '-' + serializedProduct.Product2Id;
    
                ProductItem productItem = mapNewProductItemByKey.get(key);
                serializedProduct.ProductItemId = productItem.Id;
            }
        }
        //update lstSerializedProductUpdate;
    }

    public static ProductItem createProductItem(SerializedProduct serializedProduct, Schema.Location location){
        ProductItem productItem = new ProductItem();

        productItem.LocationId = location.Id;
        productItem.QuantityUnitOfMeasure = 'Each';
        productItem.QuantityOnHand = 0;
        productItem.Status__c = 'Available';
        productItem.Product2Id = serializedProduct.Product2Id;

        return productItem;
    }

    public static void changePickedUpDeviceLocation(List<SerializedProduct> lstSerializedProduct, Map<Id, SerializedProduct> oldMap){
        List<SerializedProduct> lstSerializedProductProcess = new List<SerializedProduct>();
        for (SerializedProduct seralizedProduct : lstSerializedProduct) {
            SerializedProduct oldSerializedProduct = oldMap.get(seralizedProduct.Id);
            
            if (seralizedProduct.Picked_Up__c != oldSerializedProduct.Picked_Up__c 
                && seralizedProduct.Picked_Up__c) {
                lstSerializedProductProcess.add(seralizedProduct);
            }
        }

        if(!lstSerializedProductProcess.isEmpty()){
            changePickedUpDeviceLocation(lstSerializedProductProcess);
        }
    }

    public static void changePickedUpDeviceLocation(List<SerializedProduct> lstSerializedProduct){
        Set<Id> setCustomerId = new Set<Id>();
        Set<Id> setProductId = new Set<Id>();
        List<ProductItem> lstProductItemInsert = new List<ProductItem>();
        List<ProductItem> lstProductItemUpdate = new List<ProductItem>();
        List<SerializedProduct> lstSerializedProductUpdate = new List<SerializedProduct>();
        Map<String, ProductItem> mapProductItemByLocation = new Map<String, ProductItem>();
        Map<String, ProductItem> mapNewProductItemByKey = new Map<String, ProductItem>();

        for(SerializedProduct serializedProduct : lstSerializedProduct){
            setCustomerId.add(serializedProduct.Bank_Id__c);
            setProductId.add(serializedProduct.Product2Id);
        }

        //get user Locations
        List<Schema.Location> locations = [SELECT Id, Name, Customer_Name_Id__c FROM Location WHERE Name =: UserInfo.getName() AND LocationType = 'Technician'  LIMIT 1];

        Schema.Location loc;

        if (!locations.isEmpty()) {
            loc = locations.get(0);
        } else {
            return;
        }

        for(ProductItem productItem : [SELECT Id, LocationId, Product2Id FROM ProductItem WHERE LocationId =: loc.Id AND Product2Id IN: setProductId]){
            String key = productItem.LocationId + '-' + productItem.Product2Id;
            mapProductItemByLocation.put(key, productItem);
        }

        //set ProductItem Location 
        for (SerializedProduct serializedProduct : lstSerializedProduct) {
            String key = loc.Id + '-' + serializedProduct.Product2Id;

            ProductItem productItem = new ProductItem();
            productItem = mapProductItemByLocation.get(key);
            if(loc != null && productItem != null){
                serializedProduct.ProductItemId = productItem.Id;
                lstSerializedProductUpdate.add(serializedProduct);
            } else if(productItem == null){
                //Create Product Item in current Location
                productItem = new ProductItem();
                productItem = createProductItem(serializedProduct, loc);

                lstProductItemInsert.add(productItem);
                mapNewProductItemByKey.put(key, productItem);
                lstSerializedProductUpdate.add(serializedProduct);
            }
        }

        if(!lstProductItemInsert.isEmpty()){
            insert lstProductItemInsert;

            for(SerializedProduct serializedProduct : lstSerializedProductUpdate){
                ProductItem productItem = mapNewProductItemByKey.get(loc.Id + '-' + serializedProduct.Product2Id);
                serializedProduct.ProductItemId = productItem.Id;
            }
        }
    }

    public static void changeReturnedDeviceLocation(List<SerializedProduct> lstSerializedProduct, Map<Id, SerializedProduct> oldMap){
        List<SerializedProduct> lstSerializedProductProcess = new List<SerializedProduct>();
        for (SerializedProduct seralizedProduct : lstSerializedProduct) {
            SerializedProduct oldSerializedProduct = oldMap.get(seralizedProduct.Id);
            
            if (seralizedProduct.Returned__c != oldSerializedProduct.Returned__c 
                && seralizedProduct.Returned__c) {
                lstSerializedProductProcess.add(seralizedProduct);
            }
        }

        if(!lstSerializedProductProcess.isEmpty()){
            changeReturnedDeviceLocation(lstSerializedProductProcess);
        }
    }

    public static void changeReturnedDeviceLocation(List<SerializedProduct> lstSerializedProduct){
        Set<Id> setCustomerId = new Set<Id>();
        Set<Id> setProductId = new Set<Id>();
        List<ProductItem> lstProductItemInsert = new List<ProductItem>();
        List<ProductItem> lstProductItemUpdate = new List<ProductItem>();
        List<SerializedProduct> lstSerializedProductUpdate = new List<SerializedProduct>();
        Map<String, ProductItem> mapProductItemByLocation = new Map<String, ProductItem>();
        Map<Id, Schema.Location> mapLocationByCustomer = new Map<Id, Schema.Location>();
        Map<String, ProductItem> mapNewProductItemByKey = new Map<String, ProductItem>();

        for(SerializedProduct serializedProduct : lstSerializedProduct){
            setCustomerId.add(serializedProduct.Bank_Id__c);
            setProductId.add(serializedProduct.Product2Id);
        }

        //get new Location by Customer
        for(Schema.Location loc : [SELECT Id, Name, Customer_Name_Id__c FROM Location WHERE Customer_Name_Id__c IN: setCustomerId AND LocationType = 'Warehouse']){
            System.debug('## loc = ' + loc);

            mapLocationByCustomer.put(loc.Customer_Name_Id__c, loc);
        }

        // if(mapLocationByCustomer == null || mapLocationByCustomer.isEmpty()){
        //     throw new Exception('Location Not Found');
        // }
        System.debug('## mapLocationByCustomer = ' + mapLocationByCustomer);


        for(ProductItem productItem : [SELECT Id, LocationId, Product2Id FROM ProductItem WHERE LocationId IN: mapLocationByCustomer.values() AND Product2Id IN: setProductId]){
            System.debug('## productItem = ' + productItem);
            System.debug('## productItem.LocationId = ' + productItem.LocationId);
            System.debug('## productItem.Product2Id = ' + productItem.Product2Id);

            String key = productItem.LocationId + '-' + productItem.Product2Id;
            mapProductItemByLocation.put(key, productItem);
        }

        //set ProductItem Location 
        for (SerializedProduct serializedProduct : lstSerializedProduct) {
            System.debug('## serializedProduct.Bank_Id__c = ' + serializedProduct.Bank_Id__c);

            Schema.Location loc = mapLocationByCustomer.get(serializedProduct.Bank_Id__c);

            if(loc == null){
                serializedProduct.addError('Location Not Found');
                continue;
            }

            String key = loc.Id + '-' + serializedProduct.Product2Id;
            serializedProduct.Destination_Location_Id__c = loc.Id;

            ProductItem productItem = new ProductItem();
            productItem = mapProductItemByLocation.get(key);

            if(loc != null && productItem != null){
                serializedProduct.ProductItemId = productItem.Id;

                lstSerializedProductUpdate.add(serializedProduct);
            } else if(productItem == null){
                //Create Product Item in current Location
                productItem = new ProductItem();
                productItem = createProductItem(serializedProduct, loc);

                lstProductItemInsert.add(productItem);
                mapNewProductItemByKey.put(key, productItem);
                lstSerializedProductUpdate.add(serializedProduct);
            }
        }

        if(!lstProductItemInsert.isEmpty()){
            insert lstProductItemInsert;

            for(SerializedProduct serializedProduct : lstSerializedProductUpdate){
                Schema.Location loc = mapLocationByCustomer.get(serializedProduct.Bank_Id__c);
                String key = loc.Id + '-' + serializedProduct.Product2Id;
    
                ProductItem productItem = mapNewProductItemByKey.get(key);
                serializedProduct.ProductItemId = productItem.Id;
            }
        }
        // update lstSerializedProductUpdate;
    }
}