public without sharing class ServiceAppointmentJob implements Schedulable {
    private Set<Id> caseIds;
    
    public ServiceAppointmentJob(Set<Id> caseIds) {
            this.caseIds = caseIds;
    }
    
    public void execute(SchedulableContext context) {
            List<Case> casesToUpdate = new List<Case>();
            for (Id caseId : this.caseIds) {
                    casesToUpdate.add(new Case(
                            Id = caseId,
                            IsStopped = false,
                            SLA_Pause_Reason_list__c = null,
                            SLA_Status_list__c = null));
            }
            
            if (!casesToUpdate.isEmpty()) {
                update casesToUpdate;
            }
    }
}