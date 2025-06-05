trigger AccountTrigger on Account (before insert, after insert, before update, after update, before delete, after delete, after undelete) {
    TriggerSetting__c settings = TriggerSetting__c.getInstance();
    if(settings.Disable_Account_Trigger__c) {return;}
    TriggerDispatcher.Run(new AccountTriggerHandler());
}