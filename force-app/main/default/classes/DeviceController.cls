/**
 * @description       :
 * @author            : Remario Richards
 * @group             :
 * @last modified on  : 12-24-2023
 * @last modified by  : Remario Richards
 **/
public with sharing class DeviceController {
  
  private static final List<String> SERVICEAPPOINTMENT_STATUS = new List<String>{'Complete','Cannot Complete','Canceled By Client', 'None'};
  private static final List<String> LOGISTICS_PROFILES = new List<String>{'LOGISTICS Team','Infrastructure Logistics Team'};
  
  public class DeviceControllerException extends Exception {}
  /**
   * @description get related assets via account ids
   * @author Remario Richards | 11-04-2023
   * @param accountIds
   * @return List<AssetWrapper>
   **/
  @AuraEnabled(cacheable=true)
  public static List<AssetWrapper> getRelatedAssets(List<Id> accountIds) {
    List<AssetWrapper> assetWrappers = new List<AssetWrapper>();
    for (Asset record : [
      SELECT
        Id,
        Name,
        Account.Name,
        SerialNumber,
        AssetProvidedBy.Name,
        AssetProvidedById,
        Product2.Name,
        Product2Id,
        Terminal_id__c,
        Terminal_id__r.Name,
        Sim_Card_1__c,
        Sim_Card_1__r.SerialNumber,
        Sim_Card_2__c,
        Sim_Card_2__r.SerialNumber
      FROM Asset
      WHERE Id IN :accountIdS
      WITH SYSTEM_MODE
    ]) {
      AssetWrapper assetWrapper = new AssetWrapper(record);
      assetWrappers.add(assetWrapper);
    }
    return assetWrappers;
  }
  /**
   * @description GET records via name
   * @author Remario Richards | 11-08-2023
   * @param objectName
   * @param value
   * @return List<sObject>
   **/
  @AuraEnabled(cacheable=true)
  public static List<sObject> findRecords(String objectName, String value) {
    String likeValue = '%' + value + '%';
    String query =
      'SELECT Id, Name FROM ' +
      objectName +
      ' WHERE Name LIKE :likeValue LIMIT 10';
    return Database.query(query);
  }
  
  /**
   * @description gets a list of return order line items
   * @author Remario Richards | 11-21-2023
   * @param recordIds
   * @return List<ReturnOrderLineItemWrapper>
   **/
  @AuraEnabled
  public static List<ReturnOrderLineItemWrapper> getReturnOrderLineItems(
    List<String> recordIds
  ) {
    List<ReturnOrderLineItemWrapper> wrappers = new List<ReturnOrderLineItemWrapper>();
    try {
      for (ReturnOrderLineItem record : [
        SELECT
          Id,
          Work_Order_Id__c,
          AssetId,
          Status_list__c,
          SIM_Card_1_Status_list__c,
          SIM_Card_2_Status_list__c,
          SIM_Card_1_text__c,
          SIM_Card_2_text__c,
          SIM_Card_1_calc__c,
          SIM_Card_2_calc__c,
          Asset.Id,
          Asset.Name,
          Asset.Account.Name,
          Asset.SerialNumber,
          Asset.AssetProvidedBy.Name,
          Asset.AssetProvidedById,
          Asset.Product2.Name,
          Asset.Product2Id,
          Asset.Terminal_id__c,
          Asset.Terminal_id__r.Name,
          Asset.Sim_Card_1__c,
          Asset.Sim_Card_1__r.SerialNumber,
          Asset.Sim_Card_2__c,
          Asset.Sim_Card_2__r.SerialNumber
        FROM ReturnOrderLineItem
        WHERE Work_Order_Line_Item__c IN :recordIds
        WITH SYSTEM_MODE
        LIMIT 10
      ]) {
        wrappers.add(new ReturnOrderLineItemWrapper(record));
      }
    } catch (Exception e) {
      throw new DeviceControllerException(e.getMessage());
    }
    return wrappers;
  }

  @AuraEnabled(cacheable=false)
  public static Map<String, Object> getPickedUpDevices() { // NOPMD
    System.debug('## getPickedUpDevices ');
    
    Map<String, Object> mapReturn = new Map<String, Object>();
    List<ReturnDeviceWrapper> terminalIdWrappers = new List<ReturnDeviceWrapper>();
    ServiceResource serviceResource = new ServiceResource();
    List<ServiceAppointment> serviceAppointments = new List<ServiceAppointment>();
    List<Terminal_ID__c> terminalIds = new List<Terminal_ID__c>();
    Set<Id> setWorkOrder = new Set<Id>();
    Boolean isLogisticUser = false;
    
    User user = [SELECT Profile.Name, UserType FROM User WHERE Id =: UserInfo.getUserId() LIMIT 1];
    System.debug('## user = ' + user);
    
    if (LOGISTICS_PROFILES.contains(user.Profile.Name)) {
      isLogisticUser = true;
    } else {
      isLogisticUser = false;
    }
    System.debug('## isLogisticUser = ' + isLogisticUser);
    
    mapReturn.put('isLogisticUser', isLogisticUser);
    System.debug('## isLogisticUser = ' + isLogisticUser);
    
    if(!isLogisticUser){
      serviceResource = [SELECT Id, Name FROM ServiceResource WHERE RelatedRecordId =: UserInfo.getUserId() LIMIT 1];
    }
    
    if(serviceResource == null && !isLogisticUser){
      return mapReturn;
    }
    
    if(isLogisticUser){
      serviceAppointments = [SELECT Id, FSSK__FSK_Assigned_Service_Resource__c, FSSK__FSK_Work_Order__c FROM ServiceAppointment WHERE Status IN: SERVICEAPPOINTMENT_STATUS AND (FSSK__FSK_Work_Order__r.Service_Type_list__c LIKE '%Collection%' OR FSSK__FSK_Work_Order__r.Service_Type_list__c LIKE '%Installation%' OR FSSK__FSK_Work_Order__r.Service_Type_list__c LIKE '%Replacement%')];
    } else {
      serviceAppointments = [SELECT Id, FSSK__FSK_Assigned_Service_Resource__c, FSSK__FSK_Work_Order__c FROM ServiceAppointment WHERE FSSK__FSK_Assigned_Service_Resource__c =: serviceResource.Id AND Status IN ('Scheduled', 'Dispatched')];
      
    }
    System.debug('## serviceAppointments = ' +  serviceAppointments);
    
    for(ServiceAppointment serviceAppointment : serviceAppointments) {
      setWorkOrder.add(serviceAppointment.FSSK__FSK_Work_Order__c);
    }
    System.debug('## setWorkOrder = ' + setWorkOrder);
    
    if(isLogisticUser){
      terminalIds = [SELECT Id, Name, Bank_Name_text__c, Device_Model_Type_ID__c, Device_Model_Type_ID__r.Name,Merchant_Name_calc__c, Merchant_Name__c, Merchant_Name__r.Name, MerchantLocation_ID__c, MerchantLocation_ID__r.Name,MerchantLocation_ID__r.Address_1_text__c, MerchantLocation_ID__r.Parish_Province_State_list__c, MerchantLocation_ID__r.Country_list__c, Merchant_Location_Address_calc__c, POS_Id__c, POS_Id__r.Picked_Up__c, POS_Id__r.Returned__c, POS_Id__r.Installed__c, POS_Id__r.Not_Installed_Reason__c, Serial_Number__c, Work_Order_ID__c, Work_Order_ID__r.Case.IsClosed FROM Terminal_ID__c WHERE Work_Order_ID__c IN: setWorkOrder AND POS_Id__r.Installed__c = false AND POS_Id__r.Returned__c = false AND POS_Id__c != null];
    } else {
      terminalIds = [SELECT Id, Name, Bank_Name_text__c, Device_Model_Type_ID__c, Device_Model_Type_ID__r.Name,Merchant_Name_calc__c, Merchant_Name__c, Merchant_Name__r.Name, MerchantLocation_ID__c, MerchantLocation_ID__r.Name,MerchantLocation_ID__r.Address_1_text__c, MerchantLocation_ID__r.Parish_Province_State_list__c, MerchantLocation_ID__r.Country_list__c, Merchant_Location_Address_calc__c, POS_Id__c, POS_Id__r.Picked_Up__c, POS_Id__r.Returned__c, POS_Id__r.Installed__c, POS_Id__r.Not_Installed_Reason__c, Serial_Number__c, Work_Order_ID__c, Work_Order_ID__r.Case.IsClosed FROM Terminal_ID__c WHERE Work_Order_ID__c IN: setWorkOrder AND POS_Id__r.Picked_Up__c = false AND POS_Id__c != null];
    }
    System.debug('## terminalIds = ' + terminalIds);
    
    for(Terminal_ID__c terminalId : terminalIds){
      terminalIdWrappers.add(new ReturnDeviceWrapper(terminalId));
    }
    
    if(!terminalIdWrappers.isEmpty()){
      mapReturn.put('terminalIds', terminalIdWrappers);
    }
    System.debug('## terminalIdWrappers = ' + JSON.serialize(terminalIdWrappers));

    mapReturn.put('isLogisticUser', isLogisticUser);
    System.debug('## mapReturn = ' + mapReturn);

    return mapReturn; // NOPMD
  }
  
  
  @AuraEnabled
  public static List<ReturnDeviceWrapper> getTerminalIds(List<String> recordIds) {
    List<ReturnDeviceWrapper> terminalIdWrappers = new List<ReturnDeviceWrapper>();
    ServiceResource serviceResource = new ServiceResource();
    List<ServiceAppointment> serviceAppointments = new List<ServiceAppointment>();
    List<Terminal_ID__c> terminalIds = new List<Terminal_ID__c>();
    Set<Id> setWorkOrder = new Set<Id>();
    
    terminalIds = [SELECT Id, Name, Bank_Name_text__c, Device_Model_Type_ID__c, Device_Model_Type_ID__r.Name, Merchant_Name__c, Merchant_Name__r.Name, 
                    MerchantLocation_ID__c, MerchantLocation_ID__r.Name, Merchant_Location_Address_calc__c, POS_Id__c, POS_Id__r.Installed__c, POS_Id__r.Picked_Up__c, POS_Id__r.Returned__c,
                    POS_Id__r.Not_Installed_Reason__c, Serial_Number__c, Work_Order_ID__c,Work_Order_Line_Item_Id__c, Work_Order_ID__r.Case.IsClosed, 
                    Merchant_Name_calc__c, MerchantLocation_ID__r.Address_1_text__c, MerchantLocation_ID__r.Parish_Province_State_list__c, MerchantLocation_ID__r.Country_list__c
                    FROM Terminal_ID__c 
                    WHERE Work_Order_Line_Item_Id__c IN: recordIds AND Work_Order_Line_Item_Id__r.IsClosed = false AND POS_Id__r.Picked_Up__c = true
                    ];
    
    System.debug('## terminalIds = ' + terminalIds);
    for(Terminal_ID__c terminalId : terminalIds){
      ReturnDeviceWrapper returnDeviceWrapper = new ReturnDeviceWrapper(terminalId);
      terminalIdWrappers.add(returnDeviceWrapper);
    }
    return terminalIdWrappers;
  }
  
  @AuraEnabled
  public static void updateRecords(String jsonRecords, String workOrderLineItemId){
    System.debug('##  jsonRecords ' + jsonRecords);
    
      List<ReturnDeviceWrapper> returnDeviceList = (List<ReturnDeviceWrapper>) JSON.deserialize(jsonRecords, List<ReturnDeviceWrapper>.class);
      List<ProductConsumed> productConsumedList = new List<ProductConsumed>();
      List<ProductConsumedState> productConsumedStateList = new List<ProductConsumedState>();
      List<SerializedProduct> serializedProductListToUpdate = new List<SerializedProduct>();

      Set<Id> serializedProductIdSet = new Set<Id>();
      Set<Id> serializedProductIdSetToDelete = new Set<Id>();
      Set<Id> workOrderIdSet = new Set<Id>();
      
      for(ReturnDeviceWrapper returnDevice : returnDeviceList){
        if(returnDevice.createProductConsumption && returnDevice.installed){
          serializedProductIdSet.add(returnDevice.serializedProduct);
        }

        if(returnDevice.deleteProductConsumption && returnDevice.installed == false){
          serializedProductIdSetToDelete.add(returnDevice.serializedProduct);
          workOrderIdSet.add(returnDevice.workOrderId);
        }
      }
        List<SerializedProduct> serializedProductList = [SELECT Id, ProductItemId, Product2Id FROM SerializedProduct WHERE Id IN: serializedProductIdSet];
        System.debug('## serializedProductList ' + serializedProductList);
        
        if(!serializedProductList.isEmpty()){
          handleProductConsumedRecords(serializedProductList, returnDeviceList, workOrderLineItemId);
        }

        if(!serializedProductIdSetToDelete.isEmpty()){
          deleteProductConsumedRecords(serializedProductIdSetToDelete, workOrderIdSet);
      }
      
  }

  public static void handleProductConsumedRecords(List<SerializedProduct> serializedProductList, List<ReturnDeviceWrapper> returnDeviceList, String workOrderLineItemId){
      
      Map<Id, SerializedProduct> serializedProductMap = new Map<Id, SerializedProduct>(serializedProductList);
      Map<Id, SerializedProduct> productItemBySerializedProduct = new Map<Id, SerializedProduct>();
      List<ProductConsumed> productConsumedList = new List<ProductConsumed>();
      List<ProductConsumedState> productConsumedStateList = new List<ProductConsumedState>();
      List<SerializedProduct> serializedProductListToUpdate = new List<SerializedProduct>();
      List<ProductItem> productItemList = new List<ProductItem>();
      Map<Id, ProductItem> productItemMapToUpdate = new Map<Id, ProductItem>();
      Set<Id> productItemIdSet = new Set<Id>();
      
      for(ReturnDeviceWrapper returnDevice : returnDeviceList){
       System.debug('# returnDevice ' + returnDevice);

        if(returnDevice.createProductConsumption && returnDevice.installed){
          SerializedProduct serializedProduct = serializedProductMap.get(returnDevice.serializedProduct);
          serializedProduct.Installed__c = returnDevice.installed;
          if(!returnDevice.installed){
            serializedProduct.Not_Installed_Reason__c = returnDevice.reason;
          }

          if(serializedProduct.ProductItemId != null){
            ProductConsumed productConsumed = new ProductConsumed();
            productConsumed.WorkOrderId = returnDevice.workOrderId;
            productConsumed.WorkOrderLineItemId = workOrderLineItemId;
            productConsumed.ProductItemId = serializedProduct.ProductItemId;
            productConsumed.Serialized_Product_ID__c = returnDevice.serializedProduct;
            productConsumed.QuantityConsumed = 0;
            
            productConsumedList.add(productConsumed);
            productItemIdSet.add(serializedProductMap.get(returnDevice.serializedProduct).ProductItemId);

          }else{
            throw new DeviceControllerException('There is no ProductItem related to the Serialized Product record');
          }

        }
      }
    System.debug('# productConsumedList ' + productConsumedList);
    if(!productConsumedList.isEmpty()){
      insert productConsumedList;
      
      // productItemBySerializedProduct = populateProductItemMap(serializedProductList);

      Map<Id, ProductItem> productItemMap = new Map<Id, ProductItem>([SELECT Id, QuantityOnHand FROM ProductItem WHERE Id IN :productItemIdSet]);

      for(ProductConsumed productConsumed : productConsumedList){
        
        SerializedProduct serializedProduct = serializedProductMap.get(productConsumed.Serialized_Product_ID__c);
        
        if (serializedProduct != null) {
          //update Serialized Product 
          serializedProduct.Status = 'Consumed';
          serializedProduct.ProductItem = null;
          serializedProductListToUpdate.add(serializedProduct);
          
          //Create ProductConsumedState record
          ProductConsumedState productConsumedState = new ProductConsumedState();
          productConsumedState.ProductConsumedId = productConsumed.Id;
          productConsumedState.SerializedProductId = serializedProduct.Id;
          productConsumedState.ConsumedState = 'Consumed';
          
          productConsumedStateList.add(productConsumedState);

          //update ProductConsumed record
          productConsumed.QuantityConsumed = productConsumed.QuantityConsumed + 1;
          productConsumed.IsConsumed = true;

            ProductItem productItem = productItemMap.get(productConsumed.ProductItemId);
            
            if(productItem != null){
              productItem.QuantityOnHand = productItem.QuantityOnHand - 1;
              productItemMapToUpdate.put(productItem.Id, productItem);
              System.debug('# productItem ' + productItem);
            }
        }else{
          throw new DeviceControllerException('Error creating the ProductConsumedState record. Please, reach out to Salesforce Administrator.');
        }
        
      } 
    }      

    System.debug('## productItemMapToUpdate ' + productItemMapToUpdate);
    System.debug('## serializedProductListToUpdate ' + serializedProductListToUpdate.size());

    if(!productConsumedStateList.isEmpty() && !serializedProductListToUpdate.isEmpty() && !productItemMapToUpdate.values().isEmpty()){
      insert productConsumedStateList;
      update serializedProductListToUpdate;
      update productConsumedList;
      update productItemMapToUpdate.values();
    }
  }
  
    public static void deleteProductConsumedRecords(Set<Id> serializedProductIdSet, Set<Id> workOrderSetId){
      //Query for Product Consumed by Product Item Id 
      List<ProductConsumed> productConsumedList = [SELECT Id FROM ProductConsumed WHERE Serialized_Product_ID__c IN:serializedProductIdSet AND WorkOrderId IN:workOrderSetId];
      System.debug('## productConsumedList ' + productConsumedList);

      if(!productConsumedList.isEmpty()){
        delete productConsumedList;
      }

      List<SerializedProduct> serializedProductList = [SELECT Id, Installed__c, Not_Installed_Reason__c FROM SerializedProduct WHERE Id IN:serializedProductIdSet];
      for (SerializedProduct serializedProduct : serializedProductList) {
        serializedProduct.Installed__c = false;
        serializedProduct.Not_Installed_Reason__c = null;
      }

      update serializedProductList;
    }

    public static Map<Id, SerializedProduct> populateProductItemMap(List<SerializedProduct> serializedProductList){
      Map<Id, SerializedProduct> productItemBySerializedProduct = new Map<Id, SerializedProduct>();

      for(SerializedProduct serializedProduct : serializedProductList){
          if(!productItemBySerializedProduct.containsKey(serializedProduct.ProductItemId)){
            productItemBySerializedProduct.put(serializedProduct.ProductItemId, serializedProduct);
          }
      }

      return productItemBySerializedProduct;
    }
}