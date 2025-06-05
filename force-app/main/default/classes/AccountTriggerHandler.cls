public class AccountTriggerHandler implements ITriggerHandler{
     public void beforeInsert(List<SObject> newItems) {
         List<Account> newCaseList = (List<Account>)newItems;
         List<Account> enhancementList = new List<Account>();
    }
    public void beforeUpdate(List<SObject> newItems, Map<Id, SObject> oldItems) {
        Map<Id, Account> oldMap = (Map<Id, Account>)oldItems;
    }
    public void beforeDelete(Map<Id, SObject> oldItems) {}
    
    public void afterInsert(List<SObject> newItems) {
        List<Account> newCaseList = (List<Account>)newItems;
        AccountDomain.createEntitlements(newCaseList);
    }
    
    public void afterUpdate(List<SObject> newItems, Map<Id, SObject> oldItems) {}
    
    public void afterDelete(Map<Id, SObject> oldItems) {}

    public void afterUndelete(Map<Id, SObject> oldItems) {}
}