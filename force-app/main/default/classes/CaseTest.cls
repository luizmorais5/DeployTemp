/**
 * @description       :
 * @author            : Remario Richards
 * @group             :
 * @last modified on  : 03-18-2024
 * @last modified by  : Remario Richards
 **/
@isTest(seeAllData=true)
public with sharing class CaseTest {
  public static Map<String, Id> caseRecordTypes = CaseSelector.getRecordTypeNames(
    'Case'
  );
  public static Map<String, Id> mappedEntitlements = CaseSelector.getEntitlements();
  public static void makeData() {
    User admin = createAdminUser();
    List<Account> accounts = new List<Account>();
    System.runAs(admin) {
      Account outsideAccount = createAccount('Outside Parish', 'JMD', false);
      Account chiefOfficeJn = createAccount(
        'JN Bank Chief Office',
        'JMD',
        false
      );
      chiefOfficeJn.Parish__c = 'Kingston';
      accounts.add(outsideAccount);

      insert accounts;
    }
    //create accounts
    //create milestones
    //service appoinments
    //work orders
  }

  /**
   * @description JN Bank Regular within Radius Installation scenario 1
   * @author Remario Richards | 09-20-2023
   **/
  @isTest
  public static void shouldAssignRegularEntitlementsScenario1() {
    
    makeData();
    List<Account> accounts = [
      SELECT Id, Name, Parish__c
      FROM Account
      WHERE Name = 'JN Bank Chief Office' 
    ];
    Assert.areEqual(1, accounts.size(), 'Only 1 accounts are expected');

    RecordType merchantLocationRecordType = [SELECT Id FROM RecordType WHERE DeveloperName = 'Merchant_Location' AND SobjectType = 'Merchant_Location__c'];

    Merchant_Location__c merchantLocation = new Merchant_Location__c();
    merchantLocation.recordTypeId = merchantLocationRecordType.Id;
    merchantLocation.Country_list__c = 'Jamaica';
    merchantLocation.Parish_Province_State_list__c = 'Clarendon';
    merchantLocation.Customer_Account_ID__c =  accounts[0].Id;
    merchantLocation.Merchant_Site_Name_text__c = 'Abaco';
    merchantLocation.Address_1_text__c = '12 Hagley Park';
    insert merchantLocation;

    Case insideCase = createRegularCase();
    insideCase.Merchant_Name_ID__c = accounts[0].Id;
    insideCase.AccountId = accounts[0].Id;
    insideCase.Service_Type_list__c = 'Device Installation';
    insideCase.Merchant_Location_Id__c = merchantLocation.Id;
    insert insideCase;

    Map<Id, Account> merchantAccounts = new Map<Id, Account>(accounts);
	  Map<Id, Merchant_Location__c> merchantLocationMap = new Map<Id, Merchant_Location__c>(CaseSelector.getMerchantLocationByIds(new Set<Id>{merchantLocation.Id}));
    
    Test.startTest();
    CaseDomain.assignAllEntitlementsV2(
      new List<Case>{ insideCase },
      merchantAccounts,
      mappedEntitlements,
      merchantLocationMap
    );
    Assert.isNotNull(
      insideCase.EntitlementId,
      'JN Bank Regular within Radius Installation entitlement should be assigned'
    );
    Test.stopTest();
  }
  /**
   * @description JN Bank Regular Within Radius Troubleshoot and Training scenario 1
   * @author Remario Richards | 09-20-2023
   **/
  @isTest
  public static void shouldAssignRegularEntitlementsScenario2() {
    
    makeData();
    List<Account> accounts = [
      SELECT Id, Name, Parish__c
      FROM Account
      WHERE Name = 'JN Bank Chief Office' 
    ];
    Assert.areEqual(1, accounts.size(), 'Only 1 accounts are expected');

    RecordType merchantLocationRecordType = [SELECT Id FROM RecordType WHERE DeveloperName = 'Merchant_Location' AND SobjectType = 'Merchant_Location__c'];

    Merchant_Location__c merchantLocation = new Merchant_Location__c();
    merchantLocation.recordTypeId = merchantLocationRecordType.Id;
    merchantLocation.Country_list__c = 'Jamaica';
    merchantLocation.Parish_Province_State_list__c = 'Clarendon';
    merchantLocation.Customer_Account_ID__c =  accounts[0].Id;
    merchantLocation.Merchant_Site_Name_text__c = 'Abaco';
    merchantLocation.Address_1_text__c = '12 Hagley Park';
    insert merchantLocation;


    Case insideCase = createRegularCase();
    insideCase.Merchant_Name_ID__c = accounts[0].Id;
    insideCase.AccountId = accounts[0].Id;
    insideCase.Service_Type_list__c = 'Merchant Training';
    insideCase.Merchant_Location_Id__c = merchantLocation.Id;
    insert insideCase;

    Map<Id, Account> merchantAccounts = new Map<Id, Account>(accounts);
    Map<Id, Merchant_Location__c> merchantLocationMap = new Map<Id, Merchant_Location__c>(CaseSelector.getMerchantLocationByIds(new Set<Id>{merchantLocation.Id}));
    Test.startTest();
    CaseDomain.assignAllEntitlementsV2(
      new List<Case>{ insideCase },
      merchantAccounts,
      mappedEntitlements,
      merchantLocationMap
    );

    Assert.isNotNull(
      insideCase.EntitlementId,
      'JN Bank Regular Within Radius Troubleshoot and Training should be assigned'
    );
    Test.stopTest();
  }

  /**
   * @description JN Bank Premium Within Radius Troubleshoot and Training
   * @author Remario Richards | 09-22-2023
   **/
  @isTest
  public static void shouldAssignPremiumEntitlementsScenario1() {
    
    makeData();
    List<Account> accounts = [
      SELECT Id, Name, Parish__c
      FROM Account
      WHERE Name = 'JN Bank Chief Office' 
    ];
    Assert.areEqual(1, accounts.size(), 'Only 1 accounts are expected');

    RecordType merchantLocationRecordType = [SELECT Id FROM RecordType WHERE DeveloperName = 'Merchant_Location' AND SobjectType = 'Merchant_Location__c'];
    
    Merchant_Location__c merchantLocation = new Merchant_Location__c();
    merchantLocation.recordTypeId = merchantLocationRecordType.Id;
    merchantLocation.Country_list__c = 'Jamaica';
    merchantLocation.Parish_Province_State_list__c = 'Clarendon';
    merchantLocation.Customer_Account_ID__c =  accounts[0].Id;
    merchantLocation.Merchant_Site_Name_text__c = 'Abaco';
    merchantLocation.Address_1_text__c = '12 Hagley Park';
    insert merchantLocation;

    Case outsideCase = createPremiumCase();
    outsideCase.Merchant_Name_ID__c = accounts[0].Id;
    outsideCase.AccountId = accounts[0].Id;
    outsideCase.Merchant_Location_Id__c = merchantLocation.Id;
    insert outsideCase;

    Map<Id, Account> merchantAccounts = new Map<Id, Account>(accounts);
    Map<Id, Merchant_Location__c> merchantLocationMap = new Map<Id, Merchant_Location__c>(CaseSelector.getMerchantLocationByIds(new Set<Id>{merchantLocation.Id}));
    
    Test.startTest();
    CaseDomain.assignAllEntitlementsV2(
      new List<Case>{ outsideCase },
      merchantAccounts,
      mappedEntitlements,
      merchantLocationMap
    );

    Assert.isNotNull(
      outsideCase.EntitlementId,
      'JN Bank Premium Within Radius Troubleshoot and Training should be assigned'
    );
    Test.stopTest();
  }
  /**
   * @description process paused cases
   * @author Remario Richards | 10-05-2023
   **/
  @isTest
  public static void shouldProcessAutomaticSLAPauseScenarios() {
    makeData();
    Case outsideCase = createPremiumCase();
    outsideCase.Sub_Status_FS__c = 'Awaiting Client Response';
    outsideCase.IsStopped = false;
    CaseDomain.processAutomaticSLAPauseScenarios(new List<Case>{ outsideCase });
    Assert.areEqual(
      'Awaiting Client Response',
      outsideCase.SLA_Pause_Reason_list__c,
      'Expected client response for pause reason'
    );
  }
  /**
   * @description test unstopped and stopped cases
   * @author Remario Richards | 10-06-2023
   **/
  @isTest
  public static void shouldProcessUnStoppedCases() {
    makeData();
    Case outsideCase = createPremiumCase();
    outsideCase.Sub_Status_FS__c = 'Awaiting Client Response';
    outsideCase.IsStopped = false;
    insert outsideCase;
    outsideCase.IsStopped = true;
    outsideCase.Accumulated_Paused_Time__c = '1:2'; // 1 hour 2 minutes
    outsideCase.Sub_Status_FS__c = 'Received Device/Parts';
    update outsideCase;
    Assert.areNotEqual(
      null,
      outsideCase.Id,
      'Expected the case to be updated successfully'
    );
  }
  /**
   * @description should premium milestone completion criteria
   * @author Remario Richards | 10-06-2023
   **/
  @isTest
  public static void shouldRegularAndPremiumMilestoneCompletionCriteria_Scenarios() {
    makeData();
    Case outsideCase = createPremiumCase();
    outsideCase.Sub_Status_FS__c = 'Awaiting Client Response';
    outsideCase.IsStopped = false;
    insert outsideCase;
    
    Test.startTest();
    //scenario 1
    outsideCase.Status = 'Acknowledged';
    outsideCase.Work_Order_ID__c = null;
    outsideCase.Submitted_to_Programming__c = true;
    update outsideCase;
    //scenario 2
    outsideCase.Transferred_to_Senior_POS_Logistics__c = true;
    update outsideCase;
    //scenario 3
    outsideCase.Transferred_to_Lead_Contractor_MSO__c = true;
    update outsideCase;
    //scenario 4
    outsideCase.Service_Appointment_Created__c = true;
    update outsideCase;
    //scenario 5
    outsideCase.Status = 'Closed';
    update outsideCase;
    Test.stopTest();

    Assert.areNotEqual(
      null,
      outsideCase.Id,
      'Expected the case to be updated successfully'
    );
  }
  public static Case createRegularCase() {
    Case record = new Case(RecordTypeId = caseRecordTypes.get('POS'));
    record.Accumulated_Paused_Time__c = null;
    record.Merchant_Name_ID__c = [
      SELECT Id
      FROM Account
      WHERE Name = 'JN Bank Chief Office' 
      LIMIT 1
    ]
    .Id;
    record.Status = 'New';
    record.Priority = 'Medium';
    record.SLA_Expected_Time__c = 'Regular Service';
    record.Service_Type_list__c = 'Device Collection';
    record.AccountId = [
      SELECT Id
      FROM Account
      WHERE Name = 'JN Bank Chief Office' 
      LIMIT 1
    ]
    .Id;
    return record;
  }
  public static Case createPremiumCase() {
    Case record = new Case(RecordTypeId = caseRecordTypes.get('POS'));
    record.Accumulated_Paused_Time__c = null;
    record.Merchant_Name_ID__c = [
      SELECT Id
      FROM Account
      WHERE Name = 'JN Bank Chief Office' 
      LIMIT 1
    ]
    .Id;
    record.Status = 'New';
    record.Priority = 'Medium';
    record.SLA_Expected_Time__c = 'Premium Service';
    record.Service_Type_list__c = 'Troubleshooting Terminal Issue';
    record.AccountId = [
      SELECT Id
      FROM Account
      WHERE Name = 'JN Bank Chief Office' 
      LIMIT 1
    ]
    .Id;
    return record;
  }
  public static Account createAccount(
    String accName,
    String currencyCode,
    Boolean isInsert
  ) {
    Account account = new Account(
      Name = accName,
      CurrencyIsoCode = currencyCode,
      Parish__c = 'St. Mary',
      Country__c = 'Jamaica'
    );
    if (isInsert) {
      insert account;
    }
    return account;
  }
  public static User createAdminUser() {
    Profile profile1 = [
      SELECT Id
      FROM Profile
      WHERE name = 'System Administrator'
    ];
    User record = new User(
      ProfileId = profile1.Id,
      Username = System.now().millisecond() + 'test2@mcs.com',
      Alias = 'batman',
      Email = 'admin.tester@mcs.com',
      EmailEncodingKey = 'UTF-8',
      Firstname = 'Admin',
      Lastname = 'Tester',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      TimeZoneSidKey = 'America/Chicago'
    );
    insert record;
    return record;
  }
  @isTest
static void testScheduleAutoCaseUpdates() {
    // Create a test account (needed for contact)
    Account testAccount = new Account(Name = 'Test AutoCaseUpdates');
    insert testAccount;

    // Create a test contact
    Contact testContact = new Contact(
        FirstName = 'Test',
        LastName = 'Contact',
        AccountId = testAccount.Id,
        Email = 'test@test.com'
    );
    insert testContact;

    // Create a test work order
    WorkOrder workOrder = new WorkOrder(
        Subject = 'Test Work Order',
        Status = 'New'
    );
    insert workOrder;

    // Create a new case that will trigger the update
    Case newCase = new Case(
        RecordTypeId = caseRecordTypes.get('POS'),
        SLA_Pause_Reason_list__c = 'Other',
        Other_text__c  = 'test',
        SLA_Status_list__c = 'In Progress',
        IsStopped = false,
        Work_Order_ID__c = workOrder.Id, // Link to the work order
        ContactId = testContact.Id // Link to the contact
    );
    insert newCase;

    newCase.SLA_Pause_Reason_list__c = 'Merchant not available within SLA window - appointment set';
    newCase.SLA_Status_list__c = 'Paused';
    newCase.IsStopped = true;
    
  
    Test.startTest();
    // Update the case to invoke the trigger
    update newCase;
    Test.stopTest();

    // Verify that the service appointments were scheduled
    // List<CronTrigger> scheduledJobs = [SELECT Id, CronExpression FROM CronTrigger WHERE CronExpression LIKE 'ServiceAppointment-%'];
    // System.assertEquals(1, scheduledJobs.size(), 'One service appointment should be scheduled.');

    // Optionally, verify that the case is correctly associated with the contact
    Case updatedCase = [SELECT Id, ContactId FROM Case WHERE Id = :newCase.Id];
    System.assertEquals(testContact.Id, updatedCase.ContactId, 'The case should be associated with the correct contact.');
}

	@IsTest
	static void testPopulateCommunityLinkInSandbox() {
		Test.startTest();
		
		Case case1 = createPremiumCase();
		insert case1;

		Case updatedCase = [SELECT Id, LinkCommunityMCS__c FROM Case WHERE id = :case1.Id];

		String currentDomain = System.URL.getOrgDomainUrl().getHost();
		Boolean isProduction = !currentDomain.contains('sandbox');

		String sandboxSuffix = '';
		if (!isProduction) {
			Integer startIndex = currentDomain.indexOf('--') + 2;
			Integer endIndex = currentDomain.indexOf('.sandbox');
			sandboxSuffix = currentDomain.substring(startIndex, endIndex);
		}

		String baseLink = 'https://mcs-prod' + (isProduction ? '' : '--' + sandboxSuffix + '.sandbox') + '.my.site.com/mcs/s/';

		String expectedLink = baseLink + 'case/' + case1.Id + '/detail';

		Test.stopTest();

		System.assertEquals(expectedLink, updatedCase.LinkCommunityMCS__c);
	}
}