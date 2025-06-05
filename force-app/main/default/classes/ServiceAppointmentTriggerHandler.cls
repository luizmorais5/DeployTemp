public class ServiceAppointmentTriggerHandler implements ITriggerHandler{
    public void beforeInsert(List<SObject> newItems) {
        List<ServiceAppointment> newServiceAppointment = (List<ServiceAppointment>)newItems;
    }
    public void beforeUpdate(List<SObject> newItems, Map<Id, SObject> oldItems) {
        Map<Id, ServiceAppointment> oldMap = (Map<Id, ServiceAppointment>)oldItems;

        ServiceAppointmentDomain.validateWorkDoneStatus(newItems, oldMap);
    }
    public void beforeDelete(Map<Id, SObject> oldItems) {}

    public void afterInsert(List<SObject> newItems) {
        List<ServiceAppointment> newServiceAppointment = (List<ServiceAppointment>)newItems;
        CaseSLAManager.verifyServiceAppointmentOutsideSLA(newServiceAppointment, null);
    }

    public void afterUpdate(List<SObject> newItems, Map<Id, SObject> oldItems) {
        List<ServiceAppointment> newServiceAppointment = (List<ServiceAppointment>)newItems;
        Map<Id, ServiceAppointment> oldMap = (Map<Id, ServiceAppointment>)oldItems;

        ServiceAppointmentDomain.changeAssignedResource(newItems, oldMap);
        CaseSLAManager.verifyServiceAppointmentOutsideSLA(newServiceAppointment, oldMap);
        CaseSLAManager.unpauseSLAServiceAppointmentInProgress(newServiceAppointment, oldMap);
        CaseSLAManager.scheduleAutoCaseUpdates(newServiceAppointment, oldMap);
    }   

    public void afterDelete(Map<Id, SObject> oldItems) {}

    public void afterUndelete(Map<Id, SObject> oldItems) {}
}