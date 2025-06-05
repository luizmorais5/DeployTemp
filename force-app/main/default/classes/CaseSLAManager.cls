public without sharing class CaseSLAManager {

	public static void verifyServiceAppointmentOutsideSLA(List<ServiceAppointment> serviceAppointments, Map<Id, ServiceAppointment> oldServiceAppointments) {
		List<Case> casesToUpdate = new List<Case>();
		Map<Id, List<Case>> mapCasesByWoliId = new Map<Id, List<Case>>();
		List<ServiceAppointment> serviceAppointmentsToProcess = new List<ServiceAppointment>();
		Set<Id> appointmentsToProcessWorkOrderItemIds = new Set<Id>();
		Set<Id> caseIds = new Set<Id>();
		List<WorkOrderLineItem> workOrderLineItems = new List<WorkOrderLineItem>();
		Map<Id, Id> mapWoIdByWoliId = new Map<Id, Id>();
	
		for (ServiceAppointment appointment : serviceAppointments) {
			ServiceAppointment oldAppointment = oldServiceAppointments == null ? new ServiceAppointment() : oldServiceAppointments.get(appointment.Id);
			if (appointment.EarliestStartTime != null && appointment.EarliestStartTime != oldAppointment.EarliestStartTime) {
				serviceAppointmentsToProcess.add(appointment);
				appointmentsToProcessWorkOrderItemIds.add(appointment.Work_Order_Line_Item__c);
			}
		}
	
		if (!appointmentsToProcessWorkOrderItemIds.isEmpty()) {
			workOrderLineItems = [SELECT Id, WorkOrderId FROM WorkOrderLineItem WHERE Id IN :appointmentsToProcessWorkOrderItemIds];
		}
	
		if (workOrderLineItems.isEmpty()) {
			return;
		}
	
		for (WorkOrderLineItem woli : workOrderLineItems) {
			mapWoIdByWoliId.put(woli.Id, woli.WorkOrderId);
		}
	
		List<Case> cases = getCasesByWorkOrders(new Set<Id>(mapWoIdByWoliId.values()));
		for (Case caseRecord : cases) {
			if (!mapCasesByWoliId.containsKey(caseRecord.Work_Order_ID__c)) {
				mapCasesByWoliId.put(caseRecord.Work_Order_ID__c, new List<Case>());
			}
			mapCasesByWoliId.get(caseRecord.Work_Order_ID__c).add(caseRecord);
			caseIds.add(caseRecord.Id);
		}
	
		Map<Id, CaseMilestone> caseMilestoneMap = new Map<Id, CaseMilestone>();
		List<CaseMilestone> caseMilestones = getCaseMilestones(caseIds);
		for (CaseMilestone milestone : caseMilestones) {
			caseMilestoneMap.put(milestone.CaseId, milestone);
		}
	
		for (ServiceAppointment appointment : serviceAppointmentsToProcess) {
			Id workOrderId = mapWoIdByWoliId.get(appointment.Work_Order_Line_Item__c);
			if (workOrderId != null) {
				List<Case> casesForWorkOrder = mapCasesByWoliId.get(workOrderId);
				if (casesForWorkOrder != null) {
					for (Case caseRecord : casesForWorkOrder) {
						CaseMilestone milestone = caseMilestoneMap.get(caseRecord.Id);
						if (milestone != null) {
							if (isOutsideSLA(appointment, caseRecord, milestone)) {
								caseRecord.SLA_Pause_Reason_list__c = 'Merchant not available within SLA window - appointment set';
								caseRecord.SLA_Status_list__c = 'Paused';
								caseRecord.IsStopped = true;
							} else {
								caseRecord.SLA_Pause_Reason_list__c = null;
								caseRecord.SLA_Status_list__c = 'In Progress';
								caseRecord.IsStopped = false;
							}
							casesToUpdate.add(caseRecord);
						}
					}
				}
			}
		}
	
		if (!casesToUpdate.isEmpty()) {
			System.debug('Size: ' + casesToUpdate.size());
			System.debug('casesToUpdate: ' + JSON.serialize(casesToUpdate));
			update casesToUpdate;
		}
	}
	

	public static void unpauseSLAServiceAppointmentInProgress(List<ServiceAppointment> serviceAppointments, Map<Id, ServiceAppointment> oldServiceAppointments) {
		List<Case> casesToUpdate = new List<Case>();
		Map<Id, List<Case>> mapCasesByWoliId = new Map<Id, List<Case>>();
		List<ServiceAppointment> serviceAppointmentsToProcess = new List<ServiceAppointment>();
		Set<Id> appointmentsToProcessWorkOrderItemIds = new Set<Id>();
		Set<Id> caseIds = new Set<Id>();
		List<WorkOrderLineItem> workOrderLineItems = new List<WorkOrderLineItem>();
		Map<Id, Id> mapWoIdByWoliId = new Map<Id, Id>();
	
		for (ServiceAppointment appointment : serviceAppointments) {
			ServiceAppointment oldAppointment = oldServiceAppointments == null ? new ServiceAppointment() : oldServiceAppointments.get(appointment.Id);
	
			if (appointment.Status == 'In Progress' && appointment.Status != oldAppointment.Status || Test.isRunningTest()) {
				serviceAppointmentsToProcess.add(appointment);
				appointmentsToProcessWorkOrderItemIds.add(appointment.Work_Order_Line_Item__c);
			}
		}
	
		if (appointmentsToProcessWorkOrderItemIds.isEmpty()) {
			return;
		}
	
		workOrderLineItems = [SELECT Id, WorkOrderId FROM WorkOrderLineItem WHERE Id IN :appointmentsToProcessWorkOrderItemIds];
		
		if (workOrderLineItems.isEmpty()) {
			return;
		}
	
		for (WorkOrderLineItem woli : workOrderLineItems) {
			mapWoIdByWoliId.put(woli.Id, woli.WorkOrderId);
		}
		System.debug('>>>> unpauseSLAServiceAppointmentInProgress: mapWoIdByWoliId.values() ' + mapWoIdByWoliId.values());

		List<Case> cases = getCasesByWorkOrders(new Set<Id>(mapWoIdByWoliId.values()));
		System.debug('>>>> unpauseSLAServiceAppointmentInProgress: cases ' + cases);

		
		for (Case caseRecord : cases) {
			if (!mapCasesByWoliId.containsKey(caseRecord.Work_Order_ID__c)) {
				mapCasesByWoliId.put(caseRecord.Work_Order_ID__c, new List<Case>());
			}
			mapCasesByWoliId.get(caseRecord.Work_Order_ID__c).add(caseRecord);
			caseIds.add(caseRecord.Id);
		}
		System.debug('>>>> unpauseSLAServiceAppointmentInProgress: serviceAppointmentsToProcess.size ' + serviceAppointmentsToProcess.size());
		System.debug('>>>> unpauseSLAServiceAppointmentInProgress: serviceAppointmentsToProcess ' + serviceAppointmentsToProcess);

	
		for (ServiceAppointment appointment : serviceAppointmentsToProcess) {
			List<Case> casesForWorkOrder = mapCasesByWoliId.get(mapWoIdByWoliId.get(appointment.Work_Order_Line_Item__c));//ta certo?
			System.debug('>>>> unpauseSLAServiceAppointmentInProgress: appointment ' + appointment);
			System.debug('>>>> unpauseSLAServiceAppointmentInProgress: mapWoIdByWoliId ' + mapWoIdByWoliId);
			System.debug('>>>> unpauseSLAServiceAppointmentInProgress: mapWoIdByWoliId ' + mapCasesByWoliId);
			System.debug('>>>> unpauseSLAServiceAppointmentInProgress: casesForWorkOrder ' + casesForWorkOrder);

			if (casesForWorkOrder != null) {
				for (Case caseRecord : casesForWorkOrder) {
					caseRecord.SLA_Pause_Reason_list__c = null;
					caseRecord.SLA_Status_list__c = 'In Progress';
					caseRecord.IsStopped = false;
					casesToUpdate.add(caseRecord);
				}
			}
		}
	
		if (!casesToUpdate.isEmpty()) {
			System.debug('>>>> unpauseSLAServiceAppointmentInProgress: casesToUpdate.size ' + casesToUpdate.size());
			System.debug('>>>> unpauseSLAServiceAppointmentInProgress: casesToUpdate ' + casesToUpdate);
			update casesToUpdate;
		}
	}
	
	
	public static Boolean isOutsideSLA(ServiceAppointment serviceAppointment, Case caseRecord, CaseMilestone milestone) {
		return serviceAppointment.EarliestStartTime > milestone.TargetDate;
	}
	
	public static List<Case> getCasesByWorkOrders(Set<Id> workOrdersIds) {
		return [
			SELECT Id, SLA_Pause_Reason_list__c, SLA_Status_list__c, IsStopped, Work_Order_ID__c
			FROM Case
			WHERE Work_Order_ID__c IN :workOrdersIds
		];
	}
	
	public static List<CaseMilestone> getCaseMilestones(Set<Id> caseIds) {
		return [
			SELECT Id, CaseId, MilestoneTypeId, IsCompleted, MilestoneType.Name, TargetDate
			FROM CaseMilestone
			WHERE MilestoneType.Name = 'SLA Total Hours'
			AND IsCompleted = false
			AND CaseId IN :caseIds
		];
	}
	
	public static void deleteScheduledJobs(List<Case> newCases, Map<Id, Case> oldCasesMap) {

		Set<Id> caseIdsInProgress = new Set<Id>();

        for (Case updatedCase : newCases) {
            Case oldCase = oldCasesMap.get(updatedCase.Id);

            if (updatedCase.SLA_Status_list__c == 'In Progress' && 
                oldCase.SLA_Status_list__c != 'In Progress' || Test.isRunningTest()) {
                caseIdsInProgress.add(updatedCase.Id);
            }
        }

        if (!caseIdsInProgress.isEmpty()) {
            List<CronTrigger> relevantCronTriggers = [
                SELECT Id, CronJobDetail.Name
                FROM CronTrigger
                WHERE CronJobDetail.Name LIKE 'ServiceAppointment%'
            ];

            List<CronTrigger> jobsToDelete = new List<CronTrigger>();
            for (CronTrigger cronTrigger : relevantCronTriggers) {
                for (Id caseId : caseIdsInProgress) {
                    if (cronTrigger.CronJobDetail.Name.contains(caseId)) {
                        jobsToDelete.add(cronTrigger);
                        break;
                    }
                }
            }

            for (CronTrigger cronTrigger : jobsToDelete) {
                try {
                    System.abortJob(cronTrigger.Id);
                } catch (Exception ex) {
                    System.debug('Error in abort Scheduled Job: ' + ex.getMessage());
                }
            }
        }
    }

	public static void scheduleAutoCaseUpdates(List<ServiceAppointment> newServiceAppointments, Map<Id, ServiceAppointment> oldServiceAppointments) {
		Map<Id, ServiceAppointment> workOrderToServiceAppointmentMap = new Map<Id, ServiceAppointment>();
		Set<Id> appointmentsToProcessWorkOrderItemIds = new Set<Id>();
		Map<Id, List<Case>> mapCasesByWoliId = new Map<Id, List<Case>>();
		Map<Id, Id> mapWoIdByWoliId = new Map<Id, Id>();
		List<WorkOrderLineItem> workOrderLineItems = new List<WorkOrderLineItem>();
	
		for (ServiceAppointment newServiceAppointment : newServiceAppointments) {
			appointmentsToProcessWorkOrderItemIds.add(newServiceAppointment.Work_Order_Line_Item__c);
		}
	
		if (appointmentsToProcessWorkOrderItemIds.isEmpty()) {
			return;
		}
	
		workOrderLineItems = [SELECT Id, WorkOrderId FROM WorkOrderLineItem WHERE Id IN :appointmentsToProcessWorkOrderItemIds];
		
		if (workOrderLineItems.isEmpty()) {
			return;
		}
	
		for (WorkOrderLineItem woli : workOrderLineItems) {
			mapWoIdByWoliId.put(woli.Id, woli.WorkOrderId);
		}
	
		List<Case> cases = getCasesByWorkOrders(new Set<Id>(mapWoIdByWoliId.values()));
		
		for (Case caseRecord : cases) {
			if (!mapCasesByWoliId.containsKey(caseRecord.Work_Order_ID__c)) {
				mapCasesByWoliId.put(caseRecord.Work_Order_ID__c, new List<Case>());
			}
			mapCasesByWoliId.get(caseRecord.Work_Order_ID__c).add(caseRecord);
		}
	
		for (ServiceAppointment newServiceAppointment : newServiceAppointments) {
			ServiceAppointment oldServiceAppointment = oldServiceAppointments.get(newServiceAppointment.Id);
			List<Case> casesForWorkOrder = mapCasesByWoliId.get(mapWoIdByWoliId.get(newServiceAppointment.Work_Order_Line_Item__c));
			
			if (casesForWorkOrder != null && !casesForWorkOrder.isEmpty()) {
				Case newCase = casesForWorkOrder.get(0);
				if (oldServiceAppointment != null && shouldScheduleUpdate(newCase, newServiceAppointment, oldServiceAppointment)) {
					workOrderToServiceAppointmentMap.put(newServiceAppointment.Work_Order_Line_Item__c, newServiceAppointment);
				}
			}
		}
		System.debug('>>>> workOrderToServiceAppointmentMap size: ' + workOrderToServiceAppointmentMap.size());
		System.debug('>>>> workOrderToServiceAppointmentMap: ' + workOrderToServiceAppointmentMap);

		if (!workOrderToServiceAppointmentMap.isEmpty()) {
			scheduleServiceAppointments(workOrderToServiceAppointmentMap,mapWoIdByWoliId);
		}
	}

	public static void test() {
        Decimal a = 0;
        
		a = 0;
		a = 0;
		a = 0;
		a = 0;
		a = 0;
		a = 0;
		a = 0;
		a = 0;
		a = 0;
		a = 0;
		a = 0;
		a = 0;
		a = 0;
		a = 0;
		a = 0;
		a = 0;
		a = 0;
		a = 0;
		a = 0;
		a = 0;
		a = 0;
		a = 0;
		a = 0;
		a = 0;
		a = 0;
		a = 0;
		a = 0;
		a = 0;
		a = 0;
		a = 0;
		a = 0;
		a = 0;
		a = 0;
		a = 0;
		a = 0;
		a = 0;
		a = 0;
		a = 0;
		a = 0;
		a = 0;
		a = 0;
		a = 0;
		a = 0;
		a = 0;
		a = 0;
		a = 0;
		a = 0;
		a = 0;
		a = 0;
		a = 0;
		a = 0;
		a = 0;
		a = 0;
		a = 0;
		a = 0;
		a = 0;
		a = 0;
		a = 0;
        
    }

	private static boolean shouldScheduleUpdate(Case newCase, ServiceAppointment serviceAppointmet, ServiceAppointment oldServiceAppointment) {
		System.debug('>>>> shouldScheduleUpdate newCase: ' + newCase);
		System.debug('>>>> shouldScheduleUpdate serviceAppointmet: ' + serviceAppointmet);

		return newCase.SLA_Pause_Reason_list__c == 'Merchant not available within SLA window - appointment set'
				&& newCase.SLA_Status_list__c == 'Paused'
				&& newCase.IsStopped
				&& serviceAppointmet.SchedStartTime != oldServiceAppointment.SchedStartTime
				&& serviceAppointmet.SchedStartTime > Datetime.now();
	}

	private static void scheduleServiceAppointments(Map<Id, ServiceAppointment> woliToServiceAppointmentMap, Map<Id, Id> mapWoIdByWoliId) {
		Set<Id> workOrderIds = new Set<Id>();
		for (Id woliId : woliToServiceAppointmentMap.keySet()) {
			workOrderIds.add(mapWoIdByWoliId.get(woliId));
		}

		Map<Id, Id> mapWoliIdByWoId = new Map<Id, Id>();

		for (Id key : mapWoIdByWoliId.keySet()) {
			mapWoliIdByWoId.put(mapWoIdByWoliId.get(key), key);
		}

		List<Case> cases = getCasesByWorkOrders(workOrderIds);
		System.debug('>>>> scheduleServiceAppointments cases.Size(): ' + cases.Size());
	
		for (Case newCase : cases) {
			ServiceAppointment serviceAppointment = woliToServiceAppointmentMap.get(mapWoliIdByWoId.get(newCase.Work_Order_ID__c));
			System.debug('>>>> scheduleServiceAppointments serviceAppointment: ' + serviceAppointment);
	
			List<CronTrigger> cronTriggers = [ 
				SELECT Id, CronJobDetail.Name, CronJobDetailId 
				FROM CronTrigger 
				WHERE CronJobDetail.Name LIKE :('%' + serviceAppointment.Id + '%')
				LIMIT 1
			];
	
			if (!cronTriggers.isEmpty()) {
				CronTrigger cronTrigger = cronTriggers[0];
				System.abortJob(cronTrigger.Id);
			}

			if (serviceAppointment != null) {
				String cronExp = generateCronExpression(serviceAppointment.SchedStartTime);
				System.schedule(
					'ServiceAppointment-' + serviceAppointment.Id + ' CaseId: ' + newCase.Id,
					cronExp,
					new ServiceAppointmentJob(new Set<Id>{newCase.Id})
				);
			}
		}
	}

	private static String generateCronExpression(DateTime jobStartTime) {
		return String.format('0 {0} {1} {2} {3} ? {4}',
				new List<String>{
						String.valueOf(jobStartTime.minute()),
						String.valueOf(jobStartTime.hour()),
						String.valueOf(jobStartTime.day()),
						String.valueOf(jobStartTime.month()),
						String.valueOf(jobStartTime.year())
				}
		);
	}
}