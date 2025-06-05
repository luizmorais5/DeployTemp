public class ProductConsumedTriggerHandler implements ITriggerHandler {
    
    // This method is executed before new records are inserted
    public void beforeInsert(List<SObject> newItems) {
        // Implementation for beforeInsert if needed
    }
    
    // Method executed before records are updated
public void beforeUpdate(List<SObject> newItems, Map<Id, SObject> oldItems) {
    // Debugging message indicating the execution of the trigger handler
    System.debug('Executing ProductConsumedTriggerHandler');
    
    // Cast the list of SObjects to a list of ProductConsumed records
    List<ProductConsumed> newProductConsumptionList = (List<ProductConsumed>)newItems;
    Map<Id, ProductConsumed> oldItemsMap = (Map<Id, ProductConsumed>)oldItems;
    
    // Lists and maps to hold records and their associations
    
    List<ProductConsumed> toBeCreatedPCList = new List<ProductConsumed>();
    List<ProductConsumedState> toBeUpdatedPCSList = new List<ProductConsumedState>();
    List<ProductConsumedState> toBeUpdatedPCSWithPCList = new List<ProductConsumedState>();
    List<ProductConsumed> serializedPCList = new List<ProductConsumed>();
    Map<Id, List<ProductConsumedState>> pcPCSMap = new Map<Id, List<ProductConsumedState>>();
    Set<Id> serializedPCSet = new Set<Id>();
    
    // Iterate over each new ProductConsumed record
    for (ProductConsumed pcRec : newProductConsumptionList) {
        // If QuantityConsumed is greater than 1 and certain conditions are met, create additional records
        if ((!oldItemsMap.get(pcRec.Id).IsConsumed) && pcRec.IsConsumed && pcRec.IsProduct2Serialized && pcrec.QuantityConsumed > 1) {
            serializedPCSet.add(pcRec.Id);
            serializedPCList.add(pcRec);
            pcrec.QuantityConsumed = 1;
        }
    }
    
    // Retrieve associated ProductConsumedState records for serialized ProductConsumed records
    toBeUpdatedPCSList = [SELECT Id, ProductConsumedId,ConsumedState,SerializedProductId FROM ProductConsumedState WHERE ProductConsumedId IN :serializedPCSet];
    
    // Organize ProductConsumedState records by their associated ProductConsumedId
    for (ProductConsumedState pcsRec : toBeUpdatedPCSList) {
        if (pcPCSMap.containsKey(pcsRec.ProductConsumedId)) {
            pcPCSMap.get(pcsRec.ProductConsumedId).add(pcsRec);
        } else {
            pcPCSMap.put(pcsRec.ProductConsumedId, new List<ProductConsumedState>{ pcsRec });
        }
    }
    
    // Create additional ProductConsumed records and update QuantityConsumed for serialized ProductConsumed records
    for (ProductConsumed pcRec : serializedPCList) {
        if (pcPCSMap.get(pcRec.Id).size() > 1) {
            for (Integer i = 1; i < pcPCSMap.get(pcRec.Id).size(); i++) {
                ProductConsumed pcCopy = pcRec.clone(false, false, false, false);
                pcCopy.QuantityConsumed = 0;
                pcCopy.IsConsumed = false;
                toBeCreatedPCList.add(pcCopy);
            }
            pcRec.QuantityConsumed = 1;
        }
    }
    
    System.debug('toBeCreatedPCList'+toBeCreatedPCList.size());
    // Insert additional ProductConsumed records if any
    if (!toBeCreatedPCList.isEmpty()) {
        insert toBeCreatedPCList;
    }
    
    // Update ProductConsumedState records with the newly created ProductConsumed IDs
    List<Id> createdPCSet = new List<Id>();
    for (ProductConsumed createdPCRec : toBeCreatedPCList) {
        createdPCSet.add(createdPCRec.Id); 
    }
    Integer j = 0;
    List<ProductConsumed> updateList = new List<ProductConsumed>();
    List<ProductConsumedState> deleteList = new List<ProductConsumedState>();
    for (List<ProductConsumedState> pcsList : pcPCSMap.values()) {
        for (Integer i = 1; i < pcsList.size(); i++) {
            System.debug(pcsList[i]);
            ProductConsumedState pcs = pcsList[i].clone(false, false, false, false);
            
            System.debug(pcs.ConsumedState);
            deleteList.add(pcsList[i]);
            pcs.productConsumedId = createdPCSet[j];
            updateList.add(new PRoductConsumed(id =createdPCSet[j],QuantityConsumed = 1,isconsumed = true ));
           System.debug(pcs);
           toBeUpdatedPCSWithPCList.add(pcs);
        }
        j++;
    }
    delete deleteList;
    insert toBeUpdatedPCSWithPCList;
    update updateList;
    System.debug('delete'+deleteList.size());
    System.debug('toBeUpdatedPCSWithPCList'+toBeUpdatedPCSWithPCList.size());
}


    // Method executed after new records are inserted
    public void afterInsert(List<SObject> newItems) {
        // Implementation for afterInsert if needed
    }
    
    // Method executed after records are updated
    public void afterUpdate(List<SObject> newItems, Map<Id, SObject> oldItems) {
        // Implementation for afterUpdate if needed
    }
    
    // Method executed after records are deleted
    public void afterDelete(Map<Id, SObject> oldItems) {
        // Implementation for afterDelete if needed
    }
    
    // Method executed after records are undeleted
    public void afterUndelete(Map<Id, SObject> oldItems) {
        // Implementation for afterUndelete if needed
    }
    
    // Method executed before records are deleted
    public void beforeDelete(Map<Id, SObject> oldItems) {
        // Implementation for beforeDelete if needed
    }
}