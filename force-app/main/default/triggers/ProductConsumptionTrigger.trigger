// Trigger that fires before ProductConsumed records are inserted
trigger ProductConsumptionTrigger on ProductConsumed (before update) {
    // Retrieve trigger settings
	TriggerSetting__c settings = TriggerSetting__c.getInstance();
    
    // Check if the trigger should be disabled based on settings
    if(settings != null && settings.Disable_ProductConsumed_Trigger__c) {
        system.debug('ProductConsumed trigger disabled');
        // If trigger is disabled, exit the trigger execution
        return;
    }
    
    // If trigger is not disabled, execute the trigger handler
    TriggerDispatcher.Run(new ProductConsumedTriggerHandler());
}