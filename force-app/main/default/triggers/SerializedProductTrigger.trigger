trigger SerializedProductTrigger on SerializedProduct (before update, after update) {
    TriggerSetting__c settings = TriggerSetting__c.getInstance();
    if(settings.Disable_SerializedProduct_Trigger__c) {return;}
    TriggerDispatcher.Run(new SerializedProductTriggerHandler());
}