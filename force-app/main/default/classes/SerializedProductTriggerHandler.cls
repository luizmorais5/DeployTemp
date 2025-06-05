public class SerializedProductTriggerHandler implements ITriggerHandler{
    public void beforeInsert(List<SObject> newItems) {
    }
    public void beforeUpdate(List<SObject> newItems, Map<Id, SObject> oldItems) {
        Map<Id, SerializedProduct> oldMap = (Map<Id, SerializedProduct>)oldItems;
        SerializedProductDomain.changeProgrammedDeviceLocation(newItems, oldMap);
        SerializedProductDomain.changeUnprogrammedDeviceLocation(newItems, oldMap);
        SerializedProductDomain.changePickedUpDeviceLocation(newItems, oldMap);
        SerializedProductDomain.changeReturnedDeviceLocation(newItems, oldMap);


    }
    public void beforeDelete(Map<Id, SObject> oldItems) {}

    public void afterInsert(List<SObject> newItems) {
        List<SerializedProduct> newCaseList = (List<SerializedProduct>)newItems;
    }

    public void afterUpdate(List<SObject> newItems, Map<Id, SObject> oldItems) {
        Map<Id, SerializedProduct> oldMap = (Map<Id, SerializedProduct>)oldItems;
        
    }   

    public void afterDelete(Map<Id, SObject> oldItems) {}

    public void afterUndelete(Map<Id, SObject> oldItems) {}
}