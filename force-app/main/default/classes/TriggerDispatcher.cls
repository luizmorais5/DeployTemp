/**
* Class Name  : TriggerDispatcher
* Created By  : Thinqloud Solutions Pvt Ltd
* Date        : 07-AUG-2019
* Description : Call this method from your trigger, passing in an instance of a trigger handler which implements ITriggerHandler.
        This method will fire the appropriate methods on the handler depending on the trigger context.

* Notes       :
*/
public class TriggerDispatcher 
{
    /*
        Call this method from your trigger, passing in an instance of a trigger handler which implements ITriggerHandler.
        This method will fire the appropriate methods on the handler depending on the trigger context.
    */
    public static boolean isTest = false;
    public static void Run(ITriggerHandler handler)
    {
        // Check to see if the trigger has been disabled. If it has, return
        /*if (handler.IsDisabled())
            return;*/
             
        // Detect the current trigger context and fire the relevant methods on the trigger handler:
 
        // Before trigger logic
        if (Trigger.IsBefore )
        {
            if (Trigger.IsInsert)
                handler.beforeInsert(trigger.new);
 
            if (Trigger.IsUpdate)
                handler.beforeUpdate(trigger.new, trigger.oldMap);
 
            if (Trigger.IsDelete)
                handler.beforeDelete(trigger.oldMap);
        }
         
        // After trigger logic
        if (Trigger.IsAfter)
        {
            if (Trigger.IsInsert)
                handler.afterInsert(trigger.new);
 
            if (Trigger.IsUpdate)
                handler.afterUpdate(trigger.new, trigger.oldMap);
 
            if (trigger.IsDelete)
                handler.afterDelete(trigger.oldMap);
 
            if (trigger.isUndelete)
                handler.afterUndelete(trigger.oldMap);
        }
    }
}