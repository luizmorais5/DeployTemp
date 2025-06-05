trigger MCSCaseTrigger on Case (before insert, after insert, before update, after update, before delete, after delete, after undelete) {
    TriggerSetting__c settings = TriggerSetting__c.getInstance();
    if(settings.Disable_Case_Trigger__c) {return;}
    TriggerDispatcher.Run(new CaseTriggerHandler());
}