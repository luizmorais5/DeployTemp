@isTest
public class MCSCaseTriggerTest {
    
    public static Id hours;
    public static Account account;
    public static Contact contact;
    Public static Map<String, Group> groupMap = CaseSelector.getAvailableQueueGroup();
    Public static Map<String, List<Id>> groupMemMap = CaseSelector.getGroupsMembersMap();
    public static testmethod void prepareTestRecord(){
        hours = TestDataFactory.getBusinessHours('Office Hours');
        account = TestDataFactory.createAccountRecords('TestAccount123', 'JMD',True);
        contact = TestDataFactory.createContactRecords('TestContactFirstName', 'TestContactLastName', account.Id, 'JMD',True);
    }
    //--------------------------Ticket #2 Scenarios-------------------------------------------------------------------------
    @isTest
    public static void inSLANoTest1(){
        //User u = TestDataFactory.createUser('MCS Customer Community Plus User');
        User queueUser = TestDataFactory.getGroupMemberId('L1 Support');
        System.runAs(queueUser){
            prepareTestRecord();
            SlaProcess process = TestDataFactory.getSlaProcessNames('Critical Standard Support');
            Entitlement entitlement = TestDataFactory.createEntitlementRecords('Critical Standard Support', account.Id, System.today(), process.Id, hours, True);
            Case caseRecord = TestDataFactory.createStandardCaseRecords(account.Id, contact.Id,entitlement.Id,'General Support','Critical','New',true);      
            caseRecord.SubStatus__c = 'Client move forward:YES';
            caseRecord.In_SLA__c = 'No';
            test.startTest();
            update caseRecord;
            caseRecord = [SELECT Status,OwnerId FROM Case WHERE Id = :caseRecord.Id];
            Lead recentLead = [SELECT Case__c FROM Lead WHERE Case__c = :caseRecord.Id];
        	List<CaseMilestone> MileStone = [select Id, completionDate from CaseMilestone cm where caseId = :caseRecord.Id and completionDate = Null];        
            test.stopTest();
            System.assertEquals('Closed',caseRecord.Status,'Case status not updated');
            System.assertEquals(caseRecord.Id, recentLead.Case__c, 'Lead not created');
            System.assertEquals(UserInfo.getUserId(), caseRecord.OwnerId, 'Case Owner is Not L1 Support User');
        	System.assertEquals(0, MileStone.size(), 'Previuos Milestone Not Closed');
        }
    }
    
    @isTest
    public static void inSLANoTest2(){
        //User u = TestDataFactory.createUser('MCS Customer Community Plus User');
        User queueUser = TestDataFactory.getGroupMemberId('L1 Support');
        System.runAs(queueUser){
            prepareTestRecord();
            SlaProcess process = TestDataFactory.getSlaProcessNames('Critical Standard Support');
            Entitlement entitlement = TestDataFactory.createEntitlementRecords('Critical Standard Support', account.Id, System.today(), process.Id, hours, True);
            Case caseRecord = TestDataFactory.createStandardCaseRecords(account.Id, contact.Id,entitlement.Id,'General Support','Critical','New',true);      
            caseRecord.SubStatus__c = 'Client move forward:No';
            caseRecord.In_SLA__c = 'No';
            test.startTest();
            update caseRecord;
            caseRecord = [SELECT Status,OwnerId FROM Case WHERE Id = :caseRecord.Id];
        	List<CaseMilestone> MileStone = [select Id, completionDate from CaseMilestone cm where caseId = :caseRecord.Id and completionDate = Null];        
            test.stopTest();
            System.assertEquals('Closed',caseRecord.Status,'Case status not updated');
            System.assertEquals(UserInfo.getUserId(), caseRecord.OwnerId, 'Case Owner is Not L1 Support User');
        	System.assertEquals(0, MileStone.size(), 'Previuos Milestone Not Closed');
        }
    }
    //----------------------------------------------------------------------------------------------------------------------

    //---------------------------Ticket #7 part-1 Scenarios-----------------------------------------------------------------
    @isTest
    public static void lowStandardSupportTest(){
        //User u = TestDataFactory.createUser('MCS Customer Community Plus User');
        User queueUser = TestDataFactory.getGroupMemberId('L1 Support');
        System.runAs(queueUser){
            prepareTestRecord();
            SlaProcess process = TestDataFactory.getSlaProcessNames('Low Standard Support');
            Entitlement entitlement = TestDataFactory.createEntitlementRecords('Low Standard Support', account.Id, System.today(), process.Id, hours, False);
            Case caseRecord = TestDataFactory.createStandardCaseRecords(account.Id, contact.Id,entitlement.Id,'General Support','Low','Open',true);      
            caseRecord.In_SLA__c='Yes';
            caseRecord.L1Support_User_Assignment_Counter__c=0;
            caseRecord.Technical_Support_Needed__c=True;
            test.startTest();
            update caseRecord;
            caseRecord = [SELECT Status,OwnerId FROM Case WHERE Id = :caseRecord.Id];
        	List<CaseMilestone> MileStone = [select Id, completionDate from CaseMilestone cm where caseId = :caseRecord.Id and completionDate = Null];        
            test.stopTest();
            System.assertEquals(0, MileStone.size(), 'Previuos Milestone Not Closed');
        }
    }
    //----------------------------------------------------------------------------------------------------------------------
    //---------------------------Ticket #7 part-2 Scenarios-----------------------------------------------------------------
    @isTest
    public static void lowStandardSupportTest1(){
        //User u = TestDataFactory.createUser('MCS Customer Community Plus User');
        User queueUser = TestDataFactory.getGroupMemberId('L1 Support');
        System.runAs(queueUser){
            prepareTestRecord();
            SlaProcess process = TestDataFactory.getSlaProcessNames('Low Standard Support');
            Entitlement entitlement = TestDataFactory.createEntitlementRecords('Low Standard Support', account.Id, System.today(), process.Id, hours, False);
            Case caseRecord = TestDataFactory.createStandardCaseRecords(account.Id, contact.Id,entitlement.Id,'General Support','Low','Open',true);      
            caseRecord.In_SLA__c='Yes';
			caseRecord.Status='Closed';
            caseRecord.L1Support_User_Assignment_Counter__c=1;
            caseRecord.Technical_Support_Needed__c=False;
            test.startTest();
            update caseRecord;
			caseRecord = [SELECT Status,OwnerId FROM Case WHERE Id = :caseRecord.Id];
        	List<CaseMilestone> MileStone = [select Id, completionDate from CaseMilestone cm where caseId = :caseRecord.Id and completionDate = Null];        
            test.stopTest();
			System.assertEquals(0, MileStone.size(), 'Previuos Milestone Not Closed');
        }
    }
    //-----------------------------------------------------------------------------------------------------------------------
    //---------------------------Ticket #8 Scenarios-------------------------------------------------------------------------
    @isTest
    public static void lowStandardSupportTest2(){
        //User u = TestDataFactory.createUser('MCS Customer Community Plus User');
        User queueUser = TestDataFactory.getGroupMemberId('L1 Support');
        System.runAs(queueUser){
            prepareTestRecord();
            SlaProcess process = TestDataFactory.getSlaProcessNames('Low Standard Support');
            Entitlement entitlement = TestDataFactory.createEntitlementRecords('Low Standard Support', account.Id, System.today(), process.Id, hours, False);
            Case caseRecord = TestDataFactory.createStandardCaseRecords(account.Id, contact.Id,entitlement.Id,'General Support','Low','Open',true);      
            caseRecord.In_SLA__c='Yes';
            caseRecord.L1Support_User_Assignment_Counter__c=1;
            caseRecord.Technical_Support_Needed__c=True;
            test.startTest();
            update caseRecord;
            test.stopTest();
        }
    }
    //----------------------------------------------------------------------------------------------------------------------
    //---------------------------Ticket #87 Scenarios-------------------------------------------------------------------------
    @isTest
    public static void mediumStandardSupportTest(){
        //User u = TestDataFactory.createUser('MCS Customer Community Plus User');
        User queueUser = TestDataFactory.getGroupMemberId('L1 Support');
        System.runAs(queueUser){
            prepareTestRecord();
            SlaProcess process = TestDataFactory.getSlaProcessNames('Medium Standard Support');
            Entitlement entitlement = TestDataFactory.createEntitlementRecords('Medium Standard Support', account.Id, System.today(), process.Id, hours, True);
            Case caseRecord = TestDataFactory.createStandardCaseRecords(account.Id, contact.Id,entitlement.Id,'General Support','Medium','Open',true);      
            caseRecord.In_SLA__c='Yes';
            caseRecord.Technical_Support_Needed__c=True;
            test.startTest();
            update caseRecord;
            caseRecord = [SELECT Status,OwnerId FROM Case WHERE Id = :caseRecord.Id];
        	List<CaseMilestone> MileStone = [select Id,MilestoneType.Name,completionDate from CaseMilestone cm where caseId = :caseRecord.Id and completionDate = Null];        
            test.stopTest();
        }
    }
    
    //---------------------------------------------------------------------------------------------------------------------
    //-------------------------------Ticket #9 Scenarios-----------------------------------------------------------------------------
    @isTest
    public static void mediumStandardEscalationTest(){
        //User u = TestDataFactory.createUser('MCS Customer Community Plus User');
        User queueUser = TestDataFactory.getGroupMemberId('Technical Support L2');
        System.runAs(queueUser){
            prepareTestRecord();
            SlaProcess process = TestDataFactory.getSlaProcessNames('Medium Standard Support');
            Entitlement entitlement = TestDataFactory.createEntitlementRecords('Medium Standard Support', account.Id, System.today(), process.Id, hours, True);
            Case caseRecord = TestDataFactory.createStandardCaseRecords(account.Id, contact.Id,entitlement.Id,'General Support','Medium','Open',true);      
            caseRecord.In_SLA__c='Yes';
            caseRecord.SubStatus__c='Technical Review is required';
            test.startTest();
            update caseRecord;
            Case caseRecord1 = [SELECT Status,OwnerId FROM Case WHERE Id = :caseRecord.Id];
            List<CaseMilestone> mediumMileStone = [select Id, completionDate from CaseMilestone cm where caseId = :caseRecord1.Id and cm.MilestoneType.Name ='Standard Process : Escalation Team (MEDIUM)' and completionDate = Null];        
            test.stopTest();
        }
    }
    //-----------------------------------------------------------------------------------------------------------------------
    //---------------------------Covers- Ticket #9-ManuallyClosed------------------------------------------------------------
    @isTest
    public static void mediumStandardEscalationManualTest(){
        //User u = TestDataFactory.createUser('MCS Customer Community Plus User');
        User queueUser = TestDataFactory.getGroupMemberId('Technical Support L2');
        System.runAs(queueUser){
            prepareTestRecord();
            SlaProcess process = TestDataFactory.getSlaProcessNames('Medium Standard Support');
            Entitlement entitlement = TestDataFactory.createEntitlementRecords('Medium Standard Support', account.Id, System.today(), process.Id, hours, True);
            Case caseRecord = TestDataFactory.createStandardCaseRecords(account.Id, contact.Id,entitlement.Id,'General Support','Medium','Open',true);      
            caseRecord.In_SLA__c='Yes';
            caseRecord.SubStatus__c='Technical Review is required';
            caseRecord.Status='Closed';
            test.startTest();
            update caseRecord;
            caseRecord = [SELECT Status,OwnerId FROM Case WHERE Id = :caseRecord.Id];
            List<CaseMilestone> mediumMileStone = [select Id, completionDate from CaseMilestone cm where caseId = :caseRecord.Id and cm.MilestoneType.Name ='Standard Support : Review Case (MEDIUM)' and completionDate = Null];        
            test.stopTest();
            System.assertEquals(UserInfo.getUserId(), caseRecord.OwnerId, 'Case Owner is Not Technical Support L2 User');
        	system.assertEquals(0, mediumMileStone.size(), 'Medium Milestone Not attached');
        }
        
    }
    
    @isTest
    public static void highStandardEscalationManualTest(){
        //User u = TestDataFactory.createUser('MCS Customer Community Plus User');
        User queueUser = TestDataFactory.getGroupMemberId('Technical Support L2');
        System.runAs(queueUser){
            prepareTestRecord();
            SlaProcess process = TestDataFactory.getSlaProcessNames('High Standard Support');
            Entitlement entitlement = TestDataFactory.createEntitlementRecords('High Standard Support', account.Id, System.today(), process.Id, hours, True);
            Case caseRecord = TestDataFactory.createStandardCaseRecords(account.Id, contact.Id,entitlement.Id,'General Support','High','Open',true);      
            caseRecord.In_SLA__c='Yes';
            caseRecord.SubStatus__c='Technical Review is required';
            caseRecord.Status='Closed';
            test.startTest();
            update caseRecord;
            caseRecord = [SELECT Status,OwnerId FROM Case WHERE Id = :caseRecord.Id];
            List<CaseMilestone> highMileStone = [select Id, completionDate from CaseMilestone cm where caseId = :caseRecord.Id and cm.MilestoneType.Name ='Standard Support : Review Case (HIGH)' and completionDate = Null];        
            test.stopTest();
            System.assertEquals(UserInfo.getUserId(), caseRecord.OwnerId, 'Case Owner is Not Technical Support L2 User');
        	system.assertEquals(0, highMileStone.size(), 'High Milestone Not attached');
        }
    }
    
    @isTest
    public static void criticalStandardEscalationManualTest(){
        //User u = TestDataFactory.createUser('MCS Customer Community Plus User');
        User queueUser = TestDataFactory.getGroupMemberId('Technical Support L2');
        System.runAs(queueUser){
            prepareTestRecord();
            SlaProcess process = TestDataFactory.getSlaProcessNames('Critical Standard Support');
            Entitlement entitlement = TestDataFactory.createEntitlementRecords('Critical Standard Support', account.Id, System.today(), process.Id, hours, True);
            Case caseRecord = TestDataFactory.createStandardCaseRecords(account.Id, contact.Id,entitlement.Id,'General Support','Critical','Open',true);      
            caseRecord.In_SLA__c='Yes';
            caseRecord.SubStatus__c='Technical Review is required';
            caseRecord.Status='Closed';
            test.startTest();
            update caseRecord;
            caseRecord = [SELECT Status,OwnerId FROM Case WHERE Id = :caseRecord.Id];
            List<CaseMilestone> criticalMileStone = [select Id, completionDate from CaseMilestone cm where caseId = :caseRecord.Id and cm.MilestoneType.Name ='Standard Support : Review Case (CRITICAL)' and completionDate = Null];        
            test.stopTest();
            System.assertEquals(UserInfo.getUserId(), caseRecord.OwnerId, 'Case Owner is Not Technical Support L2 User');
        	system.assertEquals(0, criticalMileStone.size(), 'Critical Milestone Not attached');
        }
    }
    
    @isTest
    public static void lowStandardEscalationManualTest(){
        //User u = TestDataFactory.createUser('MCS Customer Community Plus User');
        User queueUser = TestDataFactory.getGroupMemberId('Technical Support L2');
        System.runAs(queueUser){
            prepareTestRecord();
            SlaProcess process = TestDataFactory.getSlaProcessNames('Low Standard Support');
            Entitlement entitlement = TestDataFactory.createEntitlementRecords('Low Standard Support', account.Id, System.today(), process.Id, hours, True);
            Case caseRecord = TestDataFactory.createStandardCaseRecords(account.Id, contact.Id,entitlement.Id,'General Support','Low','Open',true);      
            caseRecord.In_SLA__c='Yes';
            caseRecord.SubStatus__c='Technical Review is required';
            caseRecord.Status='Closed';
            test.startTest();
            update caseRecord;
            caseRecord = [SELECT Status,OwnerId FROM Case WHERE Id = :caseRecord.Id];
            List<CaseMilestone> lowMileStone = [select Id, completionDate from CaseMilestone cm where caseId = :caseRecord.Id and cm.MilestoneType.Name ='Standard Support : Review Case (LOW)' and completionDate = Null];           
            test.stopTest();
            System.assertEquals(UserInfo.getUserId(), caseRecord.OwnerId, 'Case Owner is Not Technical Support L2 User');
        	system.assertEquals(0, lowMileStone.size(), 'Low Milestone Not attached');
        }
    }
    //----------------------------------------------------------------------------------------------------------------------
    //-------------------------------Ticket #10 Scenarios-------------------------------------------------------------------
    @isTest
    public static void highStandardSupportTest(){
        //User u = TestDataFactory.createUser('MCS Customer Community Plus User');
        User queueUser = TestDataFactory.getGroupMemberId('Escalation Support Team');
        System.runAs(queueUser){
            prepareTestRecord();
            SlaProcess process = TestDataFactory.getSlaProcessNames('High Standard Support');
            Entitlement entitlement = TestDataFactory.createEntitlementRecords('High Standard Support', account.Id, System.today(), process.Id, hours, True);
            Case caseRecord = TestDataFactory.createStandardCaseRecords(account.Id, contact.Id,entitlement.Id,'General Support','High','New',true);
            caseRecord.SubStatus__c='Technical Review is required';
            caseRecord.In_SLA__c='Yes';
            caseRecord.Technical_Support_Needed__c=True;
            test.startTest();
            update caseRecord;
            caseRecord = [SELECT Status,OwnerId FROM Case WHERE Id = :caseRecord.Id];
            List<CaseMilestone> highMileStone = [select Id, completionDate from CaseMilestone cm where caseId = :caseRecord.Id and cm.MilestoneType.Name ='Standard Process : Escalation Team (HIGH)' and completionDate = Null];        
            test.stopTest();
            System.assertEquals(UserInfo.getUserId(), queueUser.Id, 'Case Owner is Not Escalation Support Team User');
        	//system.assertNotEquals(0, highMileStone.size(), 'High Milestone Not attached');
            system.assertEquals(0, highMileStone.size(), 'High Milestone Not attached');

        }
    }
    //----------------------------------------------------------------------------------------------------------------------
    //------------------------------------Hotfix----------------------------------------------------------------------------
    @isTest
    public static void highHotfixtTest(){
        //User u = TestDataFactory.createUser('MCS Customer Community Plus User');
        User queueUser = TestDataFactory.getGroupMemberId('Technical Support L2');
        System.runAs(queueUser){
            prepareTestRecord();
            SlaProcess process = TestDataFactory.getSlaProcessNames('High Hotfix Process');
            Entitlement entitlement = TestDataFactory.createEntitlementRecords('High Hotfix Process', account.Id, System.today(), process.Id, hours, True);
            Case caseRecord = TestDataFactory.createStandardCaseRecords(account.Id, contact.Id,entitlement.Id,'General Support','High','New',true);
            caseRecord.Case_Types__c='Hotfix';
            caseRecord.SubStatus__c='Technical Review is required';
            caseRecord.In_SLA__c='Yes';
            caseRecord.Technical_Support_Needed__c=True;
            test.startTest();
            update caseRecord;
            caseRecord = [SELECT Status,OwnerId FROM Case WHERE Id = :caseRecord.Id];
            List<CaseMilestone> highMileStone = [select Id, completionDate from CaseMilestone cm where caseId = :caseRecord.Id and cm.MilestoneType.Name ='Hotfix Review Case (HIGH)' and completionDate = Null];        
            test.stopTest();
            System.assertEquals(groupMap.get('L1 Support').Id, caseRecord.OwnerId, 'Case Owner is Not L1 Support User');
            system.assertNotEquals(0, highMileStone.size(), 'High Milestone Not attached');
        }
    }
    
    @isTest
    public static void criticalHotfixtTest(){
        //User u = TestDataFactory.createUser('MCS Customer Community Plus User');
        User queueUser = TestDataFactory.getGroupMemberId('Technical Support L2');
        System.runAs(queueUser){
            prepareTestRecord();
            SlaProcess process = TestDataFactory.getSlaProcessNames('Critical Hotfix Process');
            Entitlement entitlement = TestDataFactory.createEntitlementRecords('Critical Hotfix Process', account.Id, System.today(), process.Id, hours, True);
            Case caseRecord = TestDataFactory.createStandardCaseRecords(account.Id, contact.Id,entitlement.Id,'General Support','Critical','New',true);
            caseRecord.Case_Types__c='Hotfix';
            caseRecord.SubStatus__c='Technical Review is required';
            caseRecord.In_SLA__c='Yes';
            caseRecord.Technical_Support_Needed__c=True;
            test.startTest();
            update caseRecord;
            caseRecord = [SELECT Status,OwnerId FROM Case WHERE Id = :caseRecord.Id];
            List<CaseMilestone> criticalMileStone = [select Id, completionDate from CaseMilestone cm where caseId = :caseRecord.Id and cm.MilestoneType.Name ='Hotfix Review Case (CRITICAL)' and completionDate = Null];        
            test.stopTest();
            System.assertEquals(groupMap.get('L1 Support').Id, caseRecord.OwnerId, 'Case Owner is Not L1 Support User');
            system.assertNotEquals(0, criticalMileStone.size(), 'Critical Milestone Not attached');
        }
    }
    
    @isTest
    public static void mediumHotfixtTest(){
        //User u = TestDataFactory.createUser('MCS Customer Community Plus User');
        User queueUser = TestDataFactory.getGroupMemberId('Technical Support L2');
        System.runAs(queueUser){
            prepareTestRecord();
            SlaProcess process = TestDataFactory.getSlaProcessNames('Medium Hotfix Process');
            Entitlement entitlement = TestDataFactory.createEntitlementRecords('Medium Hotfix Process', account.Id, System.today(), process.Id, hours, True);
            Case caseRecord = TestDataFactory.createStandardCaseRecords(account.Id, contact.Id,entitlement.Id,'General Support','Medium','New',true);
            caseRecord.Case_Types__c='Hotfix';
            caseRecord.SubStatus__c='Technical Review is required';
            caseRecord.In_SLA__c='Yes';
            caseRecord.Technical_Support_Needed__c=True;
            test.startTest();
            update caseRecord;
            caseRecord = [SELECT Status,OwnerId FROM Case WHERE Id = :caseRecord.Id];
            List<CaseMilestone> mediumMileStone = [select Id, completionDate from CaseMilestone cm where caseId = :caseRecord.Id and cm.MilestoneType.Name ='Hotfix Review Case (MEDIUM)' and completionDate = Null];        
            test.stopTest();
            System.assertEquals(groupMap.get('L1 Support').Id, caseRecord.OwnerId, 'Case Owner is Not L1 Support User');
            system.assertNotEquals(0, mediumMileStone.size(), 'Medium Milestone Not attached');
        }
    }
    
    @isTest
    public static void lowHotfixtTest(){
        //User u = TestDataFactory.createUser('MCS Customer Community Plus User');
        User queueUser = TestDataFactory.getGroupMemberId('Technical Support L2');
        System.runAs(queueUser){
            prepareTestRecord();
            SlaProcess process = TestDataFactory.getSlaProcessNames('Low Hotfix Process');
            Entitlement entitlement = TestDataFactory.createEntitlementRecords('Low Hotfix Process', account.Id, System.today(), process.Id, hours, True);
            Case caseRecord = TestDataFactory.createStandardCaseRecords(account.Id, contact.Id,entitlement.Id,'General Support','Low','New',true);
            caseRecord.Case_Types__c='Hotfix';
            caseRecord.SubStatus__c='Technical Review is required';
            caseRecord.In_SLA__c='Yes';
            caseRecord.Technical_Support_Needed__c=True;
            test.startTest();
            update caseRecord;
            caseRecord = [SELECT Status,OwnerId FROM Case WHERE Id = :caseRecord.Id];
            List<CaseMilestone> lowMileStone = [select Id, completionDate from CaseMilestone cm where caseId = :caseRecord.Id and cm.MilestoneType.Name ='Hotfix Review Case (LOW)' and completionDate = Null];        
            test.stopTest();
            System.assertEquals(groupMap.get('L1 Support').Id, caseRecord.OwnerId, 'Case Owner is Not L1 Support User');
            system.assertNotEquals(0, lowMileStone.size(), 'Low Milestone Not attached');
        }
    }
    //-----------------------------------------------------------------------------------------------------------------------
    //------------------------------------Enhancement------------------------------------------------------------------------
    @isTest
    public static void criticalEnhancementTest(){
        //User u = TestDataFactory.createUser('MCS Customer Community Plus User');
        User queueUser = TestDataFactory.getGroupMemberId('Technical Support L2');
        System.runAs(queueUser){
            prepareTestRecord();
            SlaProcess process = TestDataFactory.getSlaProcessNames('Critical Enhancement Process');
            Entitlement entitlement = TestDataFactory.createEntitlementRecords('Critical Enhancement Process', account.Id, System.today(), process.Id, hours, True);
            Case caseRecord = TestDataFactory.createStandardCaseRecords(account.Id, contact.Id,entitlement.Id,'General Support','Critical','New',true);
            caseRecord.Case_Types__c='Enhancement';
            caseRecord.SubStatus__c='Technical Review is required';
            caseRecord.In_SLA__c='Yes';
            caseRecord.Technical_Support_Needed__c=True;
            test.startTest();
            update caseRecord;
            caseRecord = [SELECT Status,OwnerId FROM Case WHERE Id = :caseRecord.Id];
            List<CaseMilestone> criticalMileStone = [select Id, completionDate from CaseMilestone cm where caseId = :caseRecord.Id and cm.MilestoneType.Name ='Enhancement Review Case (CRITICAL)' and completionDate = Null];        
            test.stopTest();
            System.assertEquals(groupMap.get('Product Specialist').Id, caseRecord.OwnerId, 'Case Owner is Not Product Specialist User');
            system.assertNotEquals(0, criticalMileStone.size(), 'Critical Milestone Not attached');
        }
    }
    
    @isTest
    public static void highEnhancementTest(){
        //User u = TestDataFactory.createUser('MCS Customer Community Plus User');
        User queueUser = TestDataFactory.getGroupMemberId('Technical Support L2');
        System.runAs(queueUser){
            prepareTestRecord();
            SlaProcess process = TestDataFactory.getSlaProcessNames('High Enhancement Process');
            Entitlement entitlement = TestDataFactory.createEntitlementRecords('High Enhancement Process', account.Id, System.today(), process.Id, hours, True);
            Case caseRecord = TestDataFactory.createStandardCaseRecords(account.Id, contact.Id,entitlement.Id,'General Support','High','New',true);
            caseRecord.Case_Types__c='Enhancement';
            caseRecord.SubStatus__c='Technical Review is required';
            caseRecord.In_SLA__c='Yes';
            caseRecord.Technical_Support_Needed__c=True;
            test.startTest();
            update caseRecord;
            caseRecord = [SELECT Status,OwnerId FROM Case WHERE Id = :caseRecord.Id];
            List<CaseMilestone> highMileStone = [select Id, completionDate from CaseMilestone cm where caseId = :caseRecord.Id and cm.MilestoneType.Name ='Enhancement Review Case (HIGH)' and completionDate = Null];        
            test.stopTest();
            System.assertEquals(groupMap.get('Product Specialist').Id, caseRecord.OwnerId, 'Case Owner is Not Product Specialist User');
            system.assertNotEquals(0, highMileStone.size(), 'High Milestone Not attached');
        }
    }
    
    @isTest
    public static void mediumEnhancementTest(){
        //User u = TestDataFactory.createUser('MCS Customer Community Plus User');
        User queueUser = TestDataFactory.getGroupMemberId('Technical Support L2');
        System.runAs(queueUser){
            prepareTestRecord();
            SlaProcess process = TestDataFactory.getSlaProcessNames('Medium Enhancement Process');
            Entitlement entitlement = TestDataFactory.createEntitlementRecords('Medium Enhancement Process', account.Id, System.today(), process.Id, hours, True);
            Case caseRecord = TestDataFactory.createStandardCaseRecords(account.Id, contact.Id,entitlement.Id,'General Support','Medium','New',true);
            caseRecord.Case_Types__c='Enhancement';
            caseRecord.SubStatus__c='Technical Review is required';
            caseRecord.In_SLA__c='Yes';
            caseRecord.Technical_Support_Needed__c=True;
            test.startTest();
            update caseRecord;
            caseRecord = [SELECT Status,OwnerId FROM Case WHERE Id = :caseRecord.Id];
            List<CaseMilestone> mediumMileStone = [select Id, completionDate from CaseMilestone cm where caseId = :caseRecord.Id and cm.MilestoneType.Name ='Enhancement Review Case (MEDIUM)' and completionDate = Null];        
            test.stopTest();
            System.assertEquals(groupMap.get('Product Specialist').Id, caseRecord.OwnerId, 'Case Owner is Not Product Specialist User');
            system.assertNotEquals(0, mediumMileStone.size(), 'Medium Milestone Not attached');
        }
    }
    
    @isTest
    public static void lowEnhancementTest(){
        //User u = TestDataFactory.createUser('MCS Customer Community Plus User');
        User queueUser = TestDataFactory.getGroupMemberId('Technical Support L2');
        System.runAs(queueUser){
            prepareTestRecord();
            SlaProcess process = TestDataFactory.getSlaProcessNames('Low Enhancement Process');
            Entitlement entitlement = TestDataFactory.createEntitlementRecords('Low Enhancement Process', account.Id, System.today(), process.Id, hours, True);
            Case caseRecord = TestDataFactory.createStandardCaseRecords(account.Id, contact.Id,entitlement.Id,'General Support','Low','New',true);
            caseRecord.Case_Types__c='Enhancement';
            caseRecord.SubStatus__c='Technical Review is required';
            caseRecord.In_SLA__c='Yes';
            caseRecord.Technical_Support_Needed__c=True;
            test.startTest();
            update caseRecord;
            caseRecord = [SELECT Status,OwnerId FROM Case WHERE Id = :caseRecord.Id];
            List<CaseMilestone> lowMileStone = [select Id, completionDate from CaseMilestone cm where caseId = :caseRecord.Id and cm.MilestoneType.Name ='Enhancement Review Case (LOW)' and completionDate = Null];        
            test.stopTest();
            System.assertEquals(groupMap.get('Product Specialist').Id, caseRecord.OwnerId, 'Case Owner is Not Product Specialist User');
            system.assertNotEquals(0, lowMileStone.size(), 'Low Milestone Not attached');
        }
    }
    //--------------------------------------------------------------------------------------------------------------
}