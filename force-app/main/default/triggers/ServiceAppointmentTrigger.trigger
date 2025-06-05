trigger ServiceAppointmentTrigger on ServiceAppointment (before insert, before update, after insert, after update, before delete, after delete, after undelete) {
    TriggerSetting__c settings = TriggerSetting__c.getInstance();
    if(settings.Disable_ServiceAppointment_Trigger__c) {return;}
    TriggerDispatcher.Run(new ServiceAppointmentTriggerHandler());
}