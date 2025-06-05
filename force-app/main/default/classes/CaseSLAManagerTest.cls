@isTest(seeAllData=true)
public class CaseSLAManagerTest {

	public static Map<String, Id> caseRecordTypes = CaseSelector.getRecordTypeNames('Case');

	@IsTest
	static void testVerifyServiceAppointmentOutsideSLA() {
		CaseTest.makeData();

		List<Account> accounts = [
			SELECT Id, Name, Parish__c
			FROM Account
			WHERE Name = 'JN Bank Chief Office' 
		];
		
		RecordType merchantLocationRecordType = [SELECT Id FROM RecordType WHERE DeveloperName = 'Merchant_Location' AND SobjectType = 'Merchant_Location__c'];

		Merchant_Location__c merchantLocation = new Merchant_Location__c();
		merchantLocation.recordTypeId = merchantLocationRecordType.Id;
		merchantLocation.Country_list__c = 'Jamaica';
		merchantLocation.Parish_Province_State_list__c = 'Clarendon';
		merchantLocation.Customer_Account_ID__c =  accounts[0].Id;
		merchantLocation.Merchant_Site_Name_text__c = 'Abaco';
		merchantLocation.Address_1_text__c = '12 Hagley Park';

		insert merchantLocation;

		Test.startTest();

		List<WorkOrder> workOrders = new List<WorkOrder>();
		for (Integer i = 1; i <= 1; i++) {
			workOrders.add(new WorkOrder(
				Subject = 'Test Work Order ' + i,
				Status = 'New'
			));
		}
		insert workOrders;

		Contact testContact = new Contact(
			FirstName = 'Test',
			LastName = 'Contact',
			AccountId = accounts[0].Id,
			Email = 'test@test.com'
		);
		insert testContact;


		List<WorkOrderLineItem> wolis = new List<WorkOrderLineItem>();
		for (WorkOrder wo : workOrders) {
			wolis.add(new WorkOrderLineItem(
				WorkOrderId = wo.Id,
				Description = 'New'
			));
		}
		insert wolis;

		List<Case> cases = new List<Case>();
		for (WorkOrderLineItem woli : wolis) {
			cases.add(new Case(
				Work_Order_ID__c = woli.WorkOrderId, 
				RecordTypeId = caseRecordTypes.get('POS'),
				SLA_Pause_Reason_list__c = 'Other',
				Other_text__c  = 'test',
				SLA_Status_list__c = 'In Progress',
				IsStopped = false,
				Accumulated_Paused_Time__c = null,
				Merchant_Name_ID__c = accounts[0].Id,
				Status = 'New',
				Priority = 'Medium',
				SLA_Expected_Time__c = 'Regular Service',
				Service_Type_list__c = 'Device Collection',
				AccountId = accounts[0].Id,
				Merchant_Location_Id__c = merchantLocation.Id,
				ContactId = testContact.Id
			));
		}
		insert cases;

		Set<Id> casesId = new Set<Id>();
		for (Case caseRecord : cases) {
			casesId.add(caseRecord.Id);
		}

		List<ServiceAppointment> serviceAppointments = new List<ServiceAppointment>();

		Date currentDate = Date.today();
		DateTime earliestStartTime = DateTime.newInstance(currentDate, Time.newInstance(11, 0, 0, 0));
		DateTime dueDate = earliestStartTime.addDays(50);
		DateTime schedStartTime = earliestStartTime.addDays(5);
		DateTime schedEndTime = earliestStartTime.addDays(6);

		for (WorkOrderLineItem woli : wolis) {
			serviceAppointments.add(new ServiceAppointment(
				ParentRecordId = woli.Id,
				Work_Order_Line_Item__c = woli.Id,
				DueDate = System.now() + 50,
				Status = 'None',
				EarliestStartTime = schedStartTime,
				SchedStartTime = schedStartTime,
				SchedEndTime = schedEndTime
			));
		}
		insert serviceAppointments;

		Test.stopTest();

		List<Case> updatedCases = [
			SELECT Id, SLA_Pause_Reason_list__c, SLA_Status_list__c, IsStopped
			FROM Case
			WHERE Id IN :casesId
		];

		for (Case caseRecord : updatedCases) {
			//System.assertEquals('Merchant not available within SLA window - appointment set', caseRecord.SLA_Pause_Reason_list__c);
			//System.assertEquals('Paused', caseRecord.SLA_Status_list__c);
			//System.assertEquals(true, caseRecord.IsStopped);
		}
	}

	@IsTest
	static void deleteScheduledJobsTest() {
		CaseTest.makeData();

		List<Account> accounts = [
			SELECT Id, Name, Parish__c
			FROM Account
			WHERE Name = 'JN Bank Chief Office' 
		];	  
		
		RecordType merchantLocationRecordType = [SELECT Id FROM RecordType WHERE DeveloperName = 'Merchant_Location' AND SobjectType = 'Merchant_Location__c'];

		Merchant_Location__c merchantLocation = new Merchant_Location__c();
		merchantLocation.recordTypeId = merchantLocationRecordType.Id;
		merchantLocation.Country_list__c = 'Jamaica';
		merchantLocation.Parish_Province_State_list__c = 'Clarendon';
		merchantLocation.Customer_Account_ID__c =  accounts[0].Id;
		merchantLocation.Merchant_Site_Name_text__c = 'Abaco';
		merchantLocation.Address_1_text__c = '12 Hagley Park';

		insert merchantLocation;

		List<WorkOrder> workOrders = new List<WorkOrder>();
		for (Integer i = 1; i <= 1; i++) {
			workOrders.add(new WorkOrder(
				Subject = 'Test Work Order ' + i,
				Status = 'New'
			));
		}
		insert workOrders;

		Contact testContact = new Contact(
			FirstName = 'Test',
			LastName = 'Contact',
			AccountId = accounts[0].Id,
			Email = 'test@test.com'
		);
		insert testContact;

		List<WorkOrderLineItem> wolis = new List<WorkOrderLineItem>();
		for (WorkOrder wo : workOrders) {
			wolis.add(new WorkOrderLineItem(
				WorkOrderId = wo.Id,
				Description = 'New'
			));
		}
		insert wolis;

		List<Case> cases = new List<Case>();
		for (WorkOrderLineItem woli : wolis) {
			cases.add(new Case(
				Work_Order_ID__c = woli.WorkOrderId, 
				RecordTypeId = caseRecordTypes.get('POS'),
				SLA_Pause_Reason_list__c = 'Other',
				Other_text__c  = 'test',
				SLA_Status_list__c = 'Paused',
				IsStopped = false,
				Accumulated_Paused_Time__c = null,
				Merchant_Name_ID__c = accounts[0].Id,
				Status = 'New',
				Priority = 'Medium',
				SLA_Expected_Time__c = 'Regular Service',
				Service_Type_list__c = 'Device Collection',
				AccountId = accounts[0].Id,
				Merchant_Location_Id__c = merchantLocation.Id,
				ContactId = testContact.Id
			));
		}
		insert cases;

		Set<Id> casesId = new Set<Id>();
		for (Case caseRecord : cases) {
			casesId.add(caseRecord.Id);
		}

		List<ServiceAppointment> serviceAppointments = new List<ServiceAppointment>();
		for (WorkOrderLineItem woli : wolis) {
			serviceAppointments.add(new ServiceAppointment(
				ParentRecordId = woli.Id,
				Work_Order_Line_Item__c = woli.Id,
				DueDate = System.now() + 50,
				Status = 'None',
				EarliestStartTime = DateTime.now().addDays(3),
				SchedStartTime = DateTime.now().addDays(3),
				SchedEndTime = DateTime.now().addDays(4)
			));
		}
		insert serviceAppointments;

		List<CronTrigger> relevantCronTriggersBefore = [
			SELECT Id, CronJobDetail.Name,CreatedById
			FROM CronTrigger
			WHERE CronJobDetail.Name LIKE 'ServiceAppointment%'
			AND CreatedById = : UserInfo.getUserId()
		];

		Test.startTest();
		
		List<Case> updatedCases = [
			SELECT Id, SLA_Pause_Reason_list__c, SLA_Status_list__c, IsStopped
			FROM Case
			WHERE Id IN :casesId
		];

		for (Case caseRecord : updatedCases) {
			caseRecord.SLA_Status_list__c = 'In Progress';
		}

		update updatedCases;
		Test.stopTest();

		Set<Id> caseIds = new Set<Id>{updatedCases[0].Id};

        ServiceAppointmentJob job = new ServiceAppointmentJob(caseIds);
        job.execute(null);

		List<CronTrigger> relevantCronTriggersAfter = [
			SELECT Id, CronJobDetail.Name
			FROM CronTrigger
			WHERE CronJobDetail.Name LIKE 'ServiceAppointment%'
			AND CreatedById = : UserInfo.getUserId()
		];

		//System.assertEquals(1, relevantCronTriggersBefore.size());
		//System.assertEquals(0, relevantCronTriggersAfter.size());
		CaseSLAManager.test();
	}
}