@isTest
public class MCSCaseTrigger2Test {
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
     //---------------------------------------Hotfix Workflow Scenarios-----------------------------------------------
     //----------------------------------MSC 101 - 26(for Critical priority)------------------------------------------
     @isTest
    public static void criticalHotfixTest(){
        User queueUser = TestDataFactory.getGroupMemberId('Development');
        System.runAs(queueUser){
            prepareTestRecord();
            SlaProcess process = TestDataFactory.getSlaProcessNames('Critical Hotfix Process');
            Entitlement entitlement = TestDataFactory.createEntitlementRecords('Critical Hotfix Process', account.Id, System.today(), process.Id, hours, True);
            Case caseRecord = TestDataFactory.createHotfixCaseRecords(account.Id, contact.Id,entitlement.Id,'HotFix','Critical','Open',True);      
            caseRecord.Delivery_Values__c = Constants.CASE_DELIVERY_VALUE_SCRIPTAPPROVAL_SEVER;
            caseRecord.SubStatus__c= 'Fix Complete';
            test.startTest();
            update caseRecord;
            caseRecord =[select id, OwnerId from Case where Id=:caseRecord.Id];
            list<CaseMilestone> cmList =[select Id from CaseMilestone cm where caseId =: caseRecord.Id and cm.MilestoneType.Name='Script Complete : Run Script' and completionDate = Null];
            test.stopTest();
            system.assertEquals(groupMap.get('Support Specialist L2').Id, caseRecord.OwnerId, 'Case owner is not matched');
            System.assertEquals(1, cmList.size());
        }
    }
    //--------------------------------------MSC 101 - 24(for Critical priority)---------------------------------------
    @isTest
    public static void criticalHotfixTest12(){
        prepareTestRecord();
        SlaProcess process = TestDataFactory.getSlaProcessNames('Critical Hotfix Process');
        Entitlement entitlement = TestDataFactory.createEntitlementRecords('Critical Hotfix Process', account.Id, System.today(), process.Id, hours, True);
        Case caseRecord = TestDataFactory.createHotfixCaseRecords(account.Id, contact.Id,entitlement.Id,'HotFix','Critical','Open',True);      
    	//Case caseRecord = TestDataFactory.createHotfixCaseRecords1(account.Id, contact.Id, entitlement.Id, 'HotFix', 'Critical', 'Open','Technical Review is required',null,null,False,False,True);
        //caseRecord.Critical_Severity__c = True;
        //caseRecord.Script_Approval__c = True;
        caseRecord.Delivery_Values__c = Constants.CASE_DELIVERY_VALUE_SCRIPTAPPROVAL_SEVER;
        caseRecord.Status= 'Closed';
        test.startTest();
        update caseRecord;
        test.stopTest();        
    }
    //-------------------------------------MSC 101-26 (for High priority)----------------------------------------------
    @isTest
    public static void highHotfixTest(){
        User queueUser = TestDataFactory.getGroupMemberId('Development');
        System.runAs(queueUser){
            prepareTestRecord();
            SlaProcess process = TestDataFactory.getSlaProcessNames('High Hotfix Process');
            Entitlement entitlement = TestDataFactory.createEntitlementRecords('High Hotfix Process', account.Id, System.today(), process.Id, hours, True);
            Case caseRecord = TestDataFactory.createHotfixCaseRecords(account.Id, contact.Id,entitlement.Id,'HotFix','High', 'Open', True);
            test.startTest();
            //caseRecord.Critical_Severity__c = True;
            //caseRecord.Script_Approval__c = True;
            caseRecord.Delivery_Values__c = Constants.CASE_DELIVERY_VALUE_SCRIPTAPPROVAL_SEVER;
            caseRecord.SubStatus__c= 'Fix Complete';
            update caseRecord;
            caseRecord =[select id, OwnerId from Case where Id=:caseRecord.Id];
            list<CaseMilestone> cmList =[select Id from CaseMilestone cm where caseId =: caseRecord.Id and cm.MilestoneType.Name='Script Complete : Run Script' and completionDate = Null];
            test.stopTest();
            system.assertEquals(groupMap.get('Support Specialist L2').Id, caseRecord.OwnerId, 'Case owner is not matched');
            System.assertEquals(1, cmList.size());
        }
    }
    //----------------------------------MSC 101 - 24(for High priority)-----------------------------------------------
    @isTest
    public static void highHotfixTest12(){
        prepareTestRecord();
        SlaProcess process = TestDataFactory.getSlaProcessNames('High Hotfix Process');
        Entitlement entitlement = TestDataFactory.createEntitlementRecords('High Hotfix Process', account.Id, System.today(), process.Id, hours, True);
        Case caseRecord = TestDataFactory.createHotfixCaseRecords(account.Id, contact.Id,entitlement.Id,'HotFix','High','Open',True);      
    	//Case caseRecord = TestDataFactory.createHotfixCaseRecords1(account.Id, contact.Id, entitlement.Id, 'HotFix', 'Critical', 'Open','Technical Review is required',null,null,False,False,True);
        //caseRecord.Critical_Severity__c = True;
        //caseRecord.Script_Approval__c = True;
        caseRecord.Delivery_Values__c = Constants.CASE_DELIVERY_VALUE_SCRIPTAPPROVAL_SEVER;
        caseRecord.Status= 'Closed';
        test.startTest();
        update caseRecord;
        test.stopTest();        
    }
    //--------------------------------MSC 101-46(for Critical priority)--------------------------------------------
    @isTest
    public static void criticalHotfixTest11(){
        User queueUser = TestDataFactory.getGroupMemberId('L1 Support');
        System.runAs(queueUser){
            prepareTestRecord();
            SlaProcess process = TestDataFactory.getSlaProcessNames('Critical Hotfix Process');
            Entitlement entitlement = TestDataFactory.createEntitlementRecords('Critical Hotfix Process', account.Id, System.today(), process.Id, hours, True);
            Case caseRecord = TestDataFactory.createHotfixCaseRecords(account.Id, contact.Id,entitlement.Id,'HotFix','Critical','Open',True);      
            //caseRecord.Script_Approval__c = False;
            caseRecord.Delivery_Values__c = 'Bank Fix';
            caseRecord.SubStatus__c= 'Technical Review is required';
            test.startTest();
            update caseRecord;
            caseRecord =[select id, OwnerId from Case where Id=:caseRecord.Id];
            list<CaseMilestone> cmList =[select Id from CaseMilestone cm where caseId =: caseRecord.Id and cm.MilestoneType.Name='Delivery : Bank Fix' and completionDate = Null];
            test.stopTest();
            system.assertEquals(groupMap.get('Development').Id, caseRecord.OwnerId, 'Case owner is not matched');
            System.assertEquals(1, cmList.size());
        }
    }
    @isTest
    public static void criticalHotfixTest112(){
        User queueUser = TestDataFactory.getGroupMemberId('L1 Support');
        System.runAs(queueUser){
            prepareTestRecord();
            SlaProcess process = TestDataFactory.getSlaProcessNames('Critical Hotfix Process');
            Entitlement entitlement = TestDataFactory.createEntitlementRecords('Critical Hotfix Process', account.Id, System.today(), process.Id, hours, True);
            Case caseRecord = TestDataFactory.createHotfixCaseRecords(account.Id, contact.Id,entitlement.Id,'HotFix','Critical','Open',True);      
            //caseRecord.Script_Approval__c = False;
            caseRecord.Delivery_Values__c = 'Critical Hotfix All';
            caseRecord.SubStatus__c = 'Technical Review is required';
            test.startTest();
            update caseRecord;
            caseRecord =[select id, OwnerId from Case where Id=:caseRecord.Id];
            list<CaseMilestone> cmList =[select Id from CaseMilestone cm where caseId =: caseRecord.Id and cm.MilestoneType.Name='Delivery : Critical Hot Fix - All Clients' and completionDate = Null];
            test.stopTest();
            system.assertEquals(groupMap.get('Development').Id, caseRecord.OwnerId, 'Case owner is not matched');
            System.assertEquals(1, cmList.size());
        }
    }
    //--------------------------------MSC 101-21 (for Critical priority)--------------------------------------
     @isTest
    public static void criticalHotfixTest1(){
        User queueUser = TestDataFactory.getGroupMemberId('Development');
        System.runAs(queueUser){
            prepareTestRecord();
            SlaProcess process = TestDataFactory.getSlaProcessNames('Critical Hotfix Process');
            Entitlement entitlement = TestDataFactory.createEntitlementRecords('Critical Hotfix Process', account.Id, System.today(), process.Id, hours, True);
            Case caseRecord = TestDataFactory.createHotfixCaseRecords(account.Id, contact.Id,entitlement.Id,'HotFix','Critical','Open',True);      
            //caseRecord.Script_Approval__c = False;
            caseRecord.Delivery_Values__c = 'Bank Fix';
            caseRecord.SubStatus__c= 'Fix Complete';
            test.startTest();
            update caseRecord;
            caseRecord =[select id, OwnerId from Case where Id=:caseRecord.Id];
            list<CaseMilestone> cmList =[select Id from CaseMilestone cm where caseId =: caseRecord.Id and cm.MilestoneType.Name='Bank Fix : Release Sent to Client' and completionDate = Null];
            test.stopTest();
            system.assertEquals(groupMap.get('L1 Support').Id, caseRecord.OwnerId, 'Case owner is not matched');
            System.assertEquals(1, cmList.size());
        }
    }
     @isTest
    public static void criticalHotfixTest2(){
        User queueUser = TestDataFactory.getGroupMemberId('Development');
        System.runAs(queueUser){
            prepareTestRecord();
            SlaProcess process = TestDataFactory.getSlaProcessNames('Critical Hotfix Process');
            Entitlement entitlement = TestDataFactory.createEntitlementRecords('Critical Hotfix Process', account.Id, System.today(), process.Id, hours, True);
            Case caseRecord = TestDataFactory.createHotfixCaseRecords(account.Id, contact.Id,entitlement.Id,'HotFix','Critical','Open',True);      
            //Case caseRecord = TestDataFactory.createHotfixCaseRecords1(account.Id, contact.Id, entitlement.Id, 'HotFix', 'Critical', 'Open','Technical Review is required',null,null,False,False,True);
            //caseRecord.Script_Approval__c = False;
            caseRecord.Delivery_Values__c = 'Critical Hotfix All';
            caseRecord.SubStatus__c= 'Fix Complete';
            test.startTest();
            update caseRecord;
            caseRecord =[select id, OwnerId from Case where Id=:caseRecord.Id];
            list<CaseMilestone> cmList =[select Id from CaseMilestone cm where caseId =: caseRecord.Id and cm.MilestoneType.Name='Bank Fix : Release Sent to Client' and completionDate = Null];
            test.stopTest();
            system.assertEquals(groupMap.get('L1 Support').Id, caseRecord.OwnerId, 'Case owner is not matched');
            System.assertEquals(1, cmList.size());
        }
    }
    //--------------------------------MSC 101-23 (for Critical priority)--------------------------------------
     @isTest
    public static void criticalHotfixTest113(){
        prepareTestRecord();
        SlaProcess process = TestDataFactory.getSlaProcessNames('Critical Hotfix Process');
        Entitlement entitlement = TestDataFactory.createEntitlementRecords('Critical Hotfix Process', account.Id, System.today(), process.Id, hours, True);
        Case caseRecord = TestDataFactory.createHotfixCaseRecords(account.Id, contact.Id,entitlement.Id,'HotFix','Critical','Open',True);      
        //caseRecord.Script_Approval__c = False;
        caseRecord.Delivery_Values__c = 'Bank Fix';
        caseRecord.Status= 'Closed';
        test.startTest();
        update caseRecord;
        test.stopTest();
    }
    //--------------------------------MSC 101-23 (for High priority)--------------------------------------
     @isTest
    public static void highHotfixTest113(){
        prepareTestRecord();
        SlaProcess process = TestDataFactory.getSlaProcessNames('High Hotfix Process');
        Entitlement entitlement = TestDataFactory.createEntitlementRecords('High Hotfix Process', account.Id, System.today(), process.Id, hours, True);
        Case caseRecord = TestDataFactory.createHotfixCaseRecords(account.Id, contact.Id,entitlement.Id,'HotFix','High','Open',True);      
        //caseRecord.Script_Approval__c = False;
        caseRecord.Delivery_Values__c = 'Critical Hotfix All';
        caseRecord.Status= 'Closed';
        test.startTest();
        update caseRecord;
        test.stopTest();
    }
    //--------------------------------MSC 101-46(for High priority)--------------------------------------------
    @isTest
    public static void highHotfixTest11(){
        User queueUser = TestDataFactory.getGroupMemberId('L1 Support');
        System.runAs(queueUser){
            prepareTestRecord();
            SlaProcess process = TestDataFactory.getSlaProcessNames('High Hotfix Process');
            Entitlement entitlement = TestDataFactory.createEntitlementRecords('High Hotfix Process', account.Id, System.today(), process.Id, hours, True);
            Case caseRecord = TestDataFactory.createHotfixCaseRecords(account.Id, contact.Id,entitlement.Id,'HotFix','High','Open',True);      
            //caseRecord.Script_Approval__c = False;
            caseRecord.Delivery_Values__c = 'Bank Fix';
            caseRecord.SubStatus__c= 'Technical Review is required';
            test.startTest();
            update caseRecord;
            caseRecord =[select id, OwnerId from Case where Id=:caseRecord.Id];
            list<CaseMilestone> cmList =[select Id from CaseMilestone cm where caseId =: caseRecord.Id and cm.MilestoneType.Name='Delivery : Bank Fix' and completionDate = Null];
            test.stopTest();
            system.assertEquals(groupMap.get('Development').Id, caseRecord.OwnerId, 'Case owner is not matched');
            System.assertEquals(1, cmList.size());
        }
    }
    @isTest
    public static void highHotfixTest112(){
        User queueUser = TestDataFactory.getGroupMemberId('L1 Support');
        System.runAs(queueUser){
            prepareTestRecord();
            SlaProcess process = TestDataFactory.getSlaProcessNames('High Hotfix Process');
            Entitlement entitlement = TestDataFactory.createEntitlementRecords('High Hotfix Process', account.Id, System.today(), process.Id, hours, True);
            Case caseRecord = TestDataFactory.createHotfixCaseRecords(account.Id, contact.Id,entitlement.Id,'HotFix','High','Open',True);      
            //caseRecord.Script_Approval__c = False;
            caseRecord.Delivery_Values__c = 'Critical Hotfix All';
            caseRecord.SubStatus__c = 'Technical Review is required';
            test.startTest();
            update caseRecord;
            caseRecord =[select id, OwnerId from Case where Id=:caseRecord.Id];
            list<CaseMilestone> cmList =[select Id from CaseMilestone cm where caseId =: caseRecord.Id and cm.MilestoneType.Name='Delivery : Critical Hot Fix - All Clients' and completionDate = Null];
            test.stopTest();
            system.assertEquals(groupMap.get('Development').Id, caseRecord.OwnerId, 'Case owner is not matched');
            System.assertEquals(1, cmList.size());
        }
    }
                                           
    //--------------------------------MSC 101-21 (for High priority)-------------------------------------
    @isTest
    public static void highHotfixTest1(){
        User queueUser = TestDataFactory.getGroupMemberId('Development');
        System.runAs(queueUser){
            prepareTestRecord();
            SlaProcess process = TestDataFactory.getSlaProcessNames('High Hotfix Process');
            Entitlement entitlement = TestDataFactory.createEntitlementRecords('High Hotfix Process', account.Id, System.today(), process.Id, hours, True);
            Case caseRecord = TestDataFactory.createHotfixCaseRecords(account.Id, contact.Id,entitlement.Id,'HotFix','High', 'Open', True);
            //Case caseRecord = TestDataFactory.createHotfixCaseRecords1(account.Id, contact.Id, entitlement.Id, 'HotFix', 'High', 'Open','Technical Review is required','Script Approval - Standard',null,True,True,True);
            //caseRecord.Script_Approval__c = False;
            caseRecord.Delivery_Values__c = 'Bank Fix';
            caseRecord.SubStatus__c= 'Fix Complete';
            test.startTest();
            update caseRecord;
            caseRecord =[select id, OwnerId from Case where Id=:caseRecord.Id];
            list<CaseMilestone> cmList =[select Id from CaseMilestone cm where caseId =: caseRecord.Id and cm.MilestoneType.Name='Bank Fix : Release Sent to Client' and completionDate = Null];
            test.stopTest();
            system.assertEquals(groupMap.get('L1 Support').Id, caseRecord.OwnerId, 'Case owner is not matched');
            System.assertEquals(1, cmList.size());
        }
    }
    @isTest
    public static void highHotfixTest2(){
        User queueUser = TestDataFactory.getGroupMemberId('Development');
        System.runAs(queueUser){
            prepareTestRecord();
            SlaProcess process = TestDataFactory.getSlaProcessNames('High Hotfix Process');
            Entitlement entitlement = TestDataFactory.createEntitlementRecords('High Hotfix Process', account.Id, System.today(), process.Id, hours, True);
            Case caseRecord = TestDataFactory.createHotfixCaseRecords(account.Id, contact.Id,entitlement.Id,'HotFix','High', 'Open', True);
            //Case caseRecord = TestDataFactory.createHotfixCaseRecords1(account.Id, contact.Id, entitlement.Id, 'HotFix', 'High', 'Open','Technical Review is required','Script Approval - Standard',null,True,True,True);
            //caseRecord.Script_Approval__c = False;
            caseRecord.Delivery_Values__c = 'Critical Hotfix All';
            caseRecord.SubStatus__c= 'Fix Complete';
            test.startTest();
            update caseRecord;
            caseRecord =[select id, OwnerId from Case where Id=:caseRecord.Id];
            list<CaseMilestone> cmList =[select Id from CaseMilestone cm where caseId =: caseRecord.Id and cm.MilestoneType.Name='Bank Fix : Release Sent to Client' and completionDate = Null];
            test.stopTest();
            system.assertEquals(groupMap.get('L1 Support').Id, caseRecord.OwnerId, 'Case owner is not matched');
            System.assertEquals(1, cmList.size());
        }
    }
    //--------------------------------MSC (101-18, 101-19) or 101-22 (for Critical priority)-----------------------------
    @isTest
    public static void criticalHotfixTest3(){
        User queueUser = TestDataFactory.getGroupMemberId('L1 Support');
        System.runAs(queueUser){
            prepareTestRecord();
            SlaProcess process = TestDataFactory.getSlaProcessNames('Critical Hotfix Process');
            Entitlement entitlement = TestDataFactory.createEntitlementRecords('Critical Hotfix Process', account.Id, System.today(), process.Id, hours, True);
            Case caseRecord = TestDataFactory.createHotfixCaseRecords(account.Id, contact.Id,entitlement.Id,'HotFix','Critical','Open',True);      
            //caseRecord.Script_Approval__c = True;
            //caseRecord.Critical_Severity__c = False;
            caseRecord.Delivery_Values__c = 'Script Approval - Standard';
            caseRecord.SubStatus__c= 'Technical Review is required';
            test.startTest();
            update caseRecord;
            caseRecord =[select id, OwnerId from Case where Id=:caseRecord.Id];
            list<CaseMilestone> cmList =[select Id from CaseMilestone cm where caseId =: caseRecord.Id and cm.MilestoneType.Name='CRITICAL : Support Creates Script' and completionDate = Null];
            test.stopTest();
            system.assertEquals(groupMap.get('Support Specialist L2').Id, caseRecord.OwnerId, 'Case owner is not matched');
            System.assertEquals(1, cmList.size());
        }
    }
    //--------------------------------MSC 101-25 (for Critical priority)-------------------------------------
    @isTest
    public static void criticalHotfixTest4(){
        User queueUser = TestDataFactory.getGroupMemberId('Support Specialist L2');
        System.runAs(queueUser){
            prepareTestRecord();
            SlaProcess process = TestDataFactory.getSlaProcessNames('Critical Hotfix Process');
            Entitlement entitlement = TestDataFactory.createEntitlementRecords('Critical Hotfix Process', account.Id, System.today(), process.Id, hours, True);
            Case caseRecord = TestDataFactory.createHotfixCaseRecords(account.Id, contact.Id,entitlement.Id,'HotFix','Critical','Open',True);      
            //caseRecord.Script_Approval__c = True;
            //caseRecord.Critical_Severity__c = False;
            caseRecord.Delivery_Values__c = 'Script Approval - Standard';
            caseRecord.SubStatus__c= 'Fix Complete - Pending Approval';
            test.startTest();
            update caseRecord;
            caseRecord =[select id, OwnerId from Case where Id=:caseRecord.Id];
            list<CaseMilestone> cmList =[select Id from CaseMilestone cm where caseId =: caseRecord.Id and cm.MilestoneType.Name='Script Complete : Pending Approval' and completionDate = Null];
            test.stopTest();
            system.assertEquals(groupMap.get('Development').Id, caseRecord.OwnerId, 'Case owner is not matched');
            System.assertEquals(1, cmList.size());
        }
    }
    //--------------------------------MSC 101-37-Scenario#1 (for Critical priority)-------------------------------------
    @isTest
    public static void criticalHotfixTest5(){
        User queueUser = TestDataFactory.getGroupMemberId('Development');
        System.runAs(queueUser){
            prepareTestRecord();
            SlaProcess process = TestDataFactory.getSlaProcessNames('Critical Hotfix Process');
            Entitlement entitlement = TestDataFactory.createEntitlementRecords('Critical Hotfix Process', account.Id, System.today(), process.Id, hours, True);
            Case caseRecord = TestDataFactory.createHotfixCaseRecords(account.Id, contact.Id,entitlement.Id,'HotFix','Critical','Open',True);      
            //caseRecord.Script_Approval__c = True;
            //caseRecord.Critical_Severity__c = False;
            caseRecord.Delivery_Values__c = 'Script Approval - Standard';
            //caseRecord.SubStatus__c= 'Fix Complete -  Approved';
            caseRecord.SubStatus__c= 'Fix Complete';
            test.startTest();
            update caseRecord;
            caseRecord =[select id, OwnerId from Case where Id=:caseRecord.Id];
            list<CaseMilestone> cmList =[select Id from CaseMilestone cm where caseId =: caseRecord.Id and cm.MilestoneType.Name='Script Complete : Run Script' and completionDate = Null];
            test.stopTest();
            system.assertEquals(groupMap.get('Support Specialist L2').Id, caseRecord.OwnerId, 'Case owner is not matched');
            System.assertEquals(1, cmList.size());
        }
    }
    //--------------------------------MSC 101-37-Scenario#2 (for Critical priority)-------------------------------------
    @isTest
    public static void criticalHotfixTest6(){
        User queueUser = TestDataFactory.getGroupMemberId('Development');
        System.runAs(queueUser){
            prepareTestRecord();
            SlaProcess process = TestDataFactory.getSlaProcessNames('Critical Hotfix Process');
            Entitlement entitlement = TestDataFactory.createEntitlementRecords('Critical Hotfix Process', account.Id, System.today(), process.Id, hours, True);
            Case caseRecord = TestDataFactory.createHotfixCaseRecords(account.Id, contact.Id,entitlement.Id,'HotFix','Critical','Open',True);      
            //caseRecord.Script_Approval__c = True;
            //caseRecord.Critical_Severity__c = False;
            caseRecord.Delivery_Values__c = 'Script Approval - Standard';
            caseRecord.SubStatus__c= 'Fix Complete -  Rejected';
            test.startTest();
            update caseRecord;
            caseRecord =[select id, OwnerId from Case where Id=:caseRecord.Id];
            list<CaseMilestone> cmList =[select Id from CaseMilestone cm where caseId =: caseRecord.Id and cm.MilestoneType.Name='CRITICAL : Support Creates Script' and completionDate = Null];
            test.stopTest();
            system.assertEquals(groupMap.get('Support Specialist L2').Id, caseRecord.OwnerId, 'Case owner is not matched');
            System.assertEquals(1, cmList.size());
        }
    }
    //--------------------------------MSC (101-18, 101-19) or 101-22 (for High priority)-----------------------------
    @isTest
    public static void highHotfixTest3(){
        User queueUser = TestDataFactory.getGroupMemberId('L1 Support');
        System.runAs(queueUser){
            prepareTestRecord();
            SlaProcess process = TestDataFactory.getSlaProcessNames('High Hotfix Process');
            Entitlement entitlement = TestDataFactory.createEntitlementRecords('High Hotfix Process', account.Id, System.today(), process.Id, hours, True);
            Case caseRecord = TestDataFactory.createHotfixCaseRecords(account.Id, contact.Id,entitlement.Id,'HotFix','High','Open',True);      
            //caseRecord.Script_Approval__c = True;
            //caseRecord.Critical_Severity__c = False;
            caseRecord.Delivery_Values__c = 'Script Approval - Standard';
            caseRecord.SubStatus__c= 'Technical Review is required';
            test.startTest();
            update caseRecord;
            caseRecord =[select id, OwnerId from Case where Id=:caseRecord.Id];
            list<CaseMilestone> cmList =[select Id from CaseMilestone cm where caseId =: caseRecord.Id and cm.MilestoneType.Name='Support Creates Script: HIGH' and completionDate = Null];
            test.stopTest();
            system.assertEquals(groupMap.get('Support Specialist L2').Id, caseRecord.OwnerId, 'Case owner is not matched');
            System.assertEquals(1, cmList.size());
        }
    }
    //--------------------------------MSC 101-25 (for High priority)-------------------------------------
    @isTest
    public static void highHotfixTest4(){
        User queueUser = TestDataFactory.getGroupMemberId('Support Specialist L2');
        System.runAs(queueUser){
            prepareTestRecord();
            SlaProcess process = TestDataFactory.getSlaProcessNames('High Hotfix Process');
            Entitlement entitlement = TestDataFactory.createEntitlementRecords('High Hotfix Process', account.Id, System.today(), process.Id, hours, True);
            Case caseRecord = TestDataFactory.createHotfixCaseRecords(account.Id, contact.Id,entitlement.Id,'HotFix','High','Open',True);      
            //caseRecord.Script_Approval__c = True;
            //caseRecord.Critical_Severity__c = False;
            caseRecord.Delivery_Values__c = 'Script Approval - Standard';
            caseRecord.SubStatus__c= 'Fix Complete - Pending Approval';
            test.startTest();
            update caseRecord;
            caseRecord =[select id, OwnerId from Case where Id=:caseRecord.Id];
            list<CaseMilestone> cmList =[select Id from CaseMilestone cm where caseId =: caseRecord.Id and cm.MilestoneType.Name='Script Complete : Pending Approval' and completionDate = Null];
            test.stopTest();
            system.assertEquals(groupMap.get('Development').Id, caseRecord.OwnerId, 'Case owner is not matched');
            System.assertEquals(1, cmList.size());
        }
    }
    //--------------------------------MSC 101-37-Scenario#1 (for High priority)-------------------------------------
    @isTest
    public static void highHotfixTest5(){
        User queueUser = TestDataFactory.getGroupMemberId('Development');
        System.runAs(queueUser){
            prepareTestRecord();
            SlaProcess process = TestDataFactory.getSlaProcessNames('High Hotfix Process');
            Entitlement entitlement = TestDataFactory.createEntitlementRecords('High Hotfix Process', account.Id, System.today(), process.Id, hours, True);
            Case caseRecord = TestDataFactory.createHotfixCaseRecords(account.Id, contact.Id,entitlement.Id,'HotFix','High','Open',True);      
            //caseRecord.Script_Approval__c = True;
            //caseRecord.Critical_Severity__c = False;
            caseRecord.Delivery_Values__c = 'Script Approval - Standard';
            //caseRecord.SubStatus__c= 'Fix Complete -  Approved';
            caseRecord.SubStatus__c= 'Fix Complete';
            test.startTest();
            update caseRecord;
            caseRecord =[select id, OwnerId from Case where Id=:caseRecord.Id];
            list<CaseMilestone> cmList =[select Id from CaseMilestone cm where caseId =: caseRecord.Id and cm.MilestoneType.Name='Script Complete : Run Script' and completionDate = Null];
            test.stopTest();
            system.assertEquals(groupMap.get('Support Specialist L2').Id, caseRecord.OwnerId, 'Case owner is not matched');
            System.assertEquals(1, cmList.size());
        }
    }
    //--------------------------------MSC 101-37-Scenario#2 (for High priority)-------------------------------------
    @isTest
    public static void highHotfixTest6(){
        User queueUser = TestDataFactory.getGroupMemberId('Development');
        System.runAs(queueUser){
            prepareTestRecord();
            SlaProcess process = TestDataFactory.getSlaProcessNames('High Hotfix Process');
            Entitlement entitlement = TestDataFactory.createEntitlementRecords('High Hotfix Process', account.Id, System.today(), process.Id, hours, True);
            Case caseRecord = TestDataFactory.createHotfixCaseRecords(account.Id, contact.Id,entitlement.Id,'HotFix','High','Open',True);      
            //caseRecord.Script_Approval__c = True;
            //caseRecord.Critical_Severity__c = False;
            caseRecord.Delivery_Values__c = 'Script Approval - Standard';
            caseRecord.SubStatus__c= 'Fix Complete -  Rejected';
            test.startTest();
            update caseRecord;
            caseRecord =[select id, OwnerId from Case where Id=:caseRecord.Id];
            list<CaseMilestone> cmList =[select Id from CaseMilestone cm where caseId =: caseRecord.Id and cm.MilestoneType.Name='Support Creates Script: HIGH' and completionDate = Null];
            test.stopTest();
            system.assertEquals(groupMap.get('Support Specialist L2').Id, caseRecord.OwnerId, 'Case owner is not matched');
            System.assertEquals(1, cmList.size());
        }
    }
    //--------------------------------MSC 101-20(for Medium priority)-------------------------------------
    @isTest
    public static void mediumHotfixTest(){
        User queueUser = TestDataFactory.getGroupMemberId('L1 Support');
        System.runAs(queueUser){
            prepareTestRecord();
            SlaProcess process = TestDataFactory.getSlaProcessNames('Medium Hotfix Process');
            Entitlement entitlement = TestDataFactory.createEntitlementRecords('Medium Hotfix Process', account.Id, System.today(), process.Id, hours, True);
            Case caseRecord = TestDataFactory.createHotfixCaseRecords(account.Id, contact.Id,entitlement.Id,'HotFix','Medium','Open',True);      
            caseRecord.SubStatus__c= 'Ready_for_Board_Review';
            test.startTest();
            update caseRecord;
            caseRecord =[select id, OwnerId from Case where Id=:caseRecord.Id];
            list<CaseMilestone> cmList =[select Id from CaseMilestone cm where caseId =: caseRecord.Id and cm.MilestoneType.Name='Hotfix: Board Review' and completionDate = Null];
            test.stopTest();
            system.assertEquals(groupMap.get('Hot Fix Committee').Id, caseRecord.OwnerId, 'Case owner is not matched');
            System.assertEquals(1, cmList.size());
        }
    }
    //--------------------------------MSC 101-30(for Medium priority)-------------------------------------
    @isTest
    public static void mediumHotfixTest1(){
        User queueUser = TestDataFactory.getGroupMemberId('Hot Fix Committee');
        System.runAs(queueUser){
            prepareTestRecord();
            SlaProcess process = TestDataFactory.getSlaProcessNames('Medium Hotfix Process');
            Entitlement entitlement = TestDataFactory.createEntitlementRecords('Medium Hotfix Process', account.Id, System.today(), process.Id, hours, True);
            Case caseRecord = TestDataFactory.createHotfixCaseRecords(account.Id, contact.Id,entitlement.Id,'HotFix','Medium','Open',True);      
            caseRecord.Decision_Values__c = 'Tabled';
            test.startTest();
            update caseRecord;
            list<CaseMilestone> cmList =[select Id from CaseMilestone cm where caseId =: caseRecord.Id and cm.MilestoneType.Name='Board Review : Indecision' and completionDate = Null];
            test.stopTest();
            System.assertEquals(1, cmList.size());
        }
    }
    //--------------------------------MSC 101-29(for Medium priority)-------------------------------------
    @isTest
    public static void mediumHotfixTest2(){
        User queueUser = TestDataFactory.getGroupMemberId('Hot Fix Committee');
        System.runAs(queueUser){
            prepareTestRecord();
            SlaProcess process = TestDataFactory.getSlaProcessNames('Medium Hotfix Process');
            Entitlement entitlement = TestDataFactory.createEntitlementRecords('Medium Hotfix Process', account.Id, System.today(), process.Id, hours, True);
            Case caseRecord = TestDataFactory.createHotfixCaseRecords(account.Id, contact.Id,entitlement.Id,'HotFix','Medium','Open',True);      
            caseRecord.Decision_Values__c = 'Rejected';
            test.startTest();
            update caseRecord;
            caseRecord =[select status from Case where Id =:caseRecord.Id];
            test.stopTest();
            system.assertEquals('Closed', caseRecord.Status);
        }
    }
    //--------------------------------MSC 101-28(for Medium priority)-------------------------------------
    @isTest
    public static void mediumHotfixTest3(){
        User queueUser = TestDataFactory.getGroupMemberId('Hot Fix Committee');
        System.runAs(queueUser){
            prepareTestRecord();
            SlaProcess process = TestDataFactory.getSlaProcessNames('Medium Hotfix Process');
            Entitlement entitlement = TestDataFactory.createEntitlementRecords('Medium Hotfix Process', account.Id, System.today(), process.Id, hours, True);
            Case caseRecord = TestDataFactory.createHotfixCaseRecords(account.Id, contact.Id,entitlement.Id,'HotFix','Medium','Open',True);      
            caseRecord.Decision_Values__c = 'Approved';
            test.startTest();
            update caseRecord;
            caseRecord =[select id, OwnerId from Case where Id=:caseRecord.Id];
            list<CaseMilestone> cmList =[select Id from CaseMilestone cm where caseId =: caseRecord.Id and cm.MilestoneType.Name='Post Board Developement' and completionDate = Null];
            test.stopTest();
            system.assertEquals(groupMap.get('Development').Id, caseRecord.OwnerId, 'Case owner is not matched');
            System.assertEquals(1, cmList.size());
        } 
    }
    //--------------------------------MSC 101-20(for Low priority)-------------------------------------
    @isTest
    public static void lowHotfixTest(){
        User queueUser = TestDataFactory.getGroupMemberId('L1 Support');
        System.runAs(queueUser){
            prepareTestRecord();
            SlaProcess process = TestDataFactory.getSlaProcessNames('Low Hotfix Process');
            Entitlement entitlement = TestDataFactory.createEntitlementRecords('Low Hotfix Process', account.Id, System.today(), process.Id, hours, True);
            Case caseRecord = TestDataFactory.createHotfixCaseRecords(account.Id, contact.Id,entitlement.Id,'HotFix','Low','Open',True);      
            caseRecord.SubStatus__c= 'Ready_for_Board_Review';
            test.startTest();
            update caseRecord;
            caseRecord =[select id, OwnerId from Case where Id=:caseRecord.Id];
            list<CaseMilestone> cmList =[select Id from CaseMilestone cm where caseId =: caseRecord.Id and cm.MilestoneType.Name='Hotfix: Board Review' and completionDate = Null];
            test.stopTest();
            system.assertEquals(groupMap.get('Hot Fix Committee').Id, caseRecord.OwnerId, 'Case owner is not matched');
            System.assertEquals(1, cmList.size());
        }
    }
    //--------------------------------MSC 101-30(for Low priority)-------------------------------------
    @isTest
    public static void lowHotfixTest1(){
        User queueUser = TestDataFactory.getGroupMemberId('Hot Fix Committee');
        System.runAs(queueUser){
            prepareTestRecord();
            SlaProcess process = TestDataFactory.getSlaProcessNames('Low Hotfix Process');
            Entitlement entitlement = TestDataFactory.createEntitlementRecords('Low Hotfix Process', account.Id, System.today(), process.Id, hours, True);
            Case caseRecord = TestDataFactory.createHotfixCaseRecords(account.Id, contact.Id,entitlement.Id,'HotFix','Low','Open',True);      
            caseRecord.Decision_Values__c = 'Tabled';
            test.startTest();
            update caseRecord;
            list<CaseMilestone> cmList =[select Id from CaseMilestone cm where caseId =: caseRecord.Id and cm.MilestoneType.Name='Board Review : Indecision' and completionDate = Null];
            test.stopTest();
            System.assertEquals(1, cmList.size());
        }
    }
    //--------------------------------MSC 101-29(for Low priority)-------------------------------------
    @isTest
    public static void lowHotfixTest2(){
        User queueUser = TestDataFactory.getGroupMemberId('Hot Fix Committee');
        System.runAs(queueUser){
            prepareTestRecord();
            SlaProcess process = TestDataFactory.getSlaProcessNames('Low Hotfix Process');
            Entitlement entitlement = TestDataFactory.createEntitlementRecords('Low Hotfix Process', account.Id, System.today(), process.Id, hours, True);
            Case caseRecord = TestDataFactory.createHotfixCaseRecords(account.Id, contact.Id,entitlement.Id,'HotFix','Low','Open',True);      
            caseRecord.Decision_Values__c = 'Rejected';
            test.startTest();
            update caseRecord;
            caseRecord =[select status from Case where Id =:caseRecord.Id];
            test.stopTest();
            system.assertEquals('Closed', caseRecord.Status);
        }
    }
    //--------------------------------MSC 101-28(for Low priority)-------------------------------------
    @isTest
    public static void lowHotfixTest3(){
        User queueUser = TestDataFactory.getGroupMemberId('Hot Fix Committee');
        System.runAs(queueUser){
            prepareTestRecord();
            SlaProcess process = TestDataFactory.getSlaProcessNames('Low Hotfix Process');
            Entitlement entitlement = TestDataFactory.createEntitlementRecords('Low Hotfix Process', account.Id, System.today(), process.Id, hours, True);
            Case caseRecord = TestDataFactory.createHotfixCaseRecords(account.Id, contact.Id,entitlement.Id,'HotFix','Low','Open',True);      
            caseRecord.Decision_Values__c = 'Approved';
            test.startTest();
            update caseRecord;
            caseRecord =[select id, OwnerId from Case where Id=:caseRecord.Id];
            list<CaseMilestone> cmList =[select Id from CaseMilestone cm where caseId =: caseRecord.Id and cm.MilestoneType.Name='Post Board Developement' and completionDate = Null];
            test.stopTest();
            system.assertEquals(groupMap.get('Development').Id, caseRecord.OwnerId, 'Case owner is not matched');
            System.assertEquals(1, cmList.size());
        }
    }

}