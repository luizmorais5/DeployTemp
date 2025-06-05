/**
* Class Name  : ITriggerHandler
* Created By  : Thinqloud Solutions Pvt Ltd
* Date        : 08-Oct-2020
* Description : Call this method from your trigger, passing in an instance of a trigger handler which implements ITriggerHandler.
        This method will fire the appropriate methods on the handler depending on the trigger context.

* Notes       :
*/
public interface ITriggerHandler 
{
    void beforeInsert(List<SObject> newItems);
 
    void beforeUpdate(List<SObject> newItems, Map<Id, SObject> oldItems);
 
    void beforeDelete(Map<Id, SObject> oldItems);
 
    void afterInsert(List<SObject> newItems);
 
    void afterUpdate(List<SObject> newItems, Map<Id, SObject> oldItems);
 
    void afterDelete(Map<Id, SObject> oldItems);
 
    void afterUndelete(Map<Id, SObject> oldItems);
 
    //Boolean IsDisabled();
}