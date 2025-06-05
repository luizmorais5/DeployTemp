@isTest
public class MCSCaseTriggerTest3 {
    
    public static Id hours;
    public static Account account;
    public static Contact contact;
    Public static Map<String, Group> groupMap = CaseSelector.getAvailableQueueGroup();
    Public static Map<String, List<Id>> groupMemMap = CaseSelector.getGroupsMembersMap();
    
    public static testmethod void prepareTestRecord(){
        hours = TestDataFactory.getBusinessHours('Office Hours');
        account = TestDataFactory.createAccountRecords('TestAccount1234', 'JMD',True);
        contact = TestDataFactory.createContactRecords('TestContactFirstName', 'TestContactLastName', account.Id, 'JMD',True);
    }
    
    /*
    * Method enhance_DevReviewSRSBRS_Test
    * @description : MSC 101-11 - Product Specialist recieves a case then reviews the case. 
    * After review, Product Specialist assignt the case to Development queue for their review and 
    * SRS/BRS Review 
    */
    @isTest
    public static void enhance_DevReviewSRSBRS_Test(){
        User queueUser = TestDataFactory.getGroupMemberId('Product Specialist');
        System.runAs(queueUser){
            prepareTestRecord();
            SlaProcess criticalSLA = TestDataFactory.getSlaProcessNames('Critical Enhancement Process');
            SlaProcess highSLA = TestDataFactory.getSlaProcessNames('High Enhancement Process');
            SlaProcess mediumSLA = TestDataFactory.getSlaProcessNames('Medium Enhancement Process');
            SlaProcess lowSLA = TestDataFactory.getSlaProcessNames('Low Enhancement Process');
            
            Entitlement criticalEntitlement = TestDataFactory.createEntitlementRecords('Critical Enhancement Process', account.Id, System.today(), criticalSLA.Id, hours, True);
            Entitlement highEntitlement = TestDataFactory.createEntitlementRecords('High Enhancement Process', account.Id, System.today(), highSLA.Id, hours, True);
            Entitlement mediumEntitlement = TestDataFactory.createEntitlementRecords('Medium Enhancement Process', account.Id, System.today(), mediumSLA.Id, hours, True);
            Entitlement lowEntitlement = TestDataFactory.createEntitlementRecords('Low Enhancement Process', account.Id, System.today(), lowSLA.Id, hours, True);
            
            case criticalCaseRecord = TestDataFactory.createEnhanceCaseRecords(account.Id, contact.Id, criticalEntitlement.Id, 'Critical', 'Open', True);
            case highCaseRecord = TestDataFactory.createEnhanceCaseRecords(account.Id, contact.Id, highEntitlement.Id, 'High', 'Open', True);
            case mediumCaseRecord = TestDataFactory.createEnhanceCaseRecords(account.Id, contact.Id, mediumEntitlement.Id, 'Medium', 'Open', True);
            case lowCaseRecord = TestDataFactory.createEnhanceCaseRecords(account.Id, contact.Id, lowEntitlement.Id, 'Low', 'Open', True);
            
            criticalCaseRecord.OwnerId = groupMap.get('Product Specialist').Id;
            criticalCaseRecord.SubStatus__c = 'Development';
            
            highCaseRecord.OwnerId = groupMap.get('Product Specialist').Id;
            highCaseRecord.SubStatus__c = 'Development';
            
            mediumCaseRecord.OwnerId = groupMap.get('Product Specialist').Id;
            mediumCaseRecord.SubStatus__c = 'Development';
            
            lowCaseRecord.OwnerId = groupMap.get('Product Specialist').Id;
            lowCaseRecord.SubStatus__c = 'Development';
            
            test.startTest();
            update criticalCaseRecord;
            update highCaseRecord;
            update mediumCaseRecord;
            update lowCaseRecord;
            test.stopTest();
            
            case updatedCriticalCs = [Select id,  OwnerId from case where id =: criticalCaseRecord.Id];
            case updatedHighCs = [Select id,  OwnerId from case where id =: highCaseRecord.Id];
            case updatedMediumCs = [Select id,  OwnerId from case where id =: mediumCaseRecord.Id];
            case updatedLowCs = [Select id,  OwnerId from case where id =: lowCaseRecord.Id];
            
            system.assertEquals(groupMap.get('Development').Id, updatedCriticalCs.OwnerId, 'Case owner is not Development');
            system.assertEquals(groupMap.get('Development').Id, updatedHighCs.OwnerId, 'Case owner is not Development');
            system.assertEquals(groupMap.get('Development').Id, updatedMediumCs.OwnerId, 'Case owner is not Development');
            system.assertEquals(groupMap.get('Development').Id, updatedLowCs.OwnerId, 'Case owner is not Development');
            
            List<CaseMilestone> cmsCritical = [select Id, completionDate from CaseMilestone cm where caseId = :updatedCriticalCs.Id and cm.MilestoneType.Name ='SRS/BRS: Revision (CRITICAL)' and completionDate = Null];        
            List<CaseMilestone> cmsHigh = [select Id, completionDate from CaseMilestone cm where caseId = :updatedHighCs.Id and cm.MilestoneType.Name ='SRS/BRS: Revision (HIGH)' and completionDate = Null];        
            List<CaseMilestone> cmsMedium = [select Id, completionDate from CaseMilestone cm where caseId = :updatedMediumCs.Id and cm.MilestoneType.Name ='SRS/BRS: Revision (MEDIUM)' and completionDate = Null];        
            List<CaseMilestone> cmsLow = [select Id, completionDate from CaseMilestone cm where caseId = :updatedLowCs.Id and cm.MilestoneType.Name ='SRS/BRS: Revision (LOW)' and completionDate = Null];        
            
            system.assertNotEquals(0, cmsCritical.size(), 'Critical Milestone Not attached');
            system.assertNotEquals(0, cmsHigh.size(), 'High Milestone Not attached');
            system.assertNotEquals(0, cmsMedium.size(), 'Medium Milestone Not attached');
            system.assertNotEquals(0, cmsLow.size(), 'Low Milestone Not attached');
        }
    }
    
    /*
* Method enhance_Dev_Need_Add_Information_Test
* @description : MSC 101-12 - Developer need additional information. 
* Case is assigned to Product Specialist to seek answers for the additioanl information 
*/
    @isTest
    public static void enhance_Dev_Need_Add_Information_Test(){
        User queueUser = TestDataFactory.getGroupMemberId('Development');
        System.runAs(queueUser){
            prepareTestRecord();
            SlaProcess criticalSLA = TestDataFactory.getSlaProcessNames('Critical Enhancement Process');
            SlaProcess highSLA = TestDataFactory.getSlaProcessNames('High Enhancement Process');
            SlaProcess mediumSLA = TestDataFactory.getSlaProcessNames('Medium Enhancement Process');
            SlaProcess lowSLA = TestDataFactory.getSlaProcessNames('Low Enhancement Process');
            
            Entitlement criticalEntitlement = TestDataFactory.createEntitlementRecords('Critical Enhancement Process', account.Id, System.today(), criticalSLA.Id, hours, True);
            Entitlement highEntitlement = TestDataFactory.createEntitlementRecords('High Enhancement Process', account.Id, System.today(), highSLA.Id, hours, True);
            Entitlement mediumEntitlement = TestDataFactory.createEntitlementRecords('Medium Enhancement Process', account.Id, System.today(), mediumSLA.Id, hours, True);
            Entitlement lowEntitlement = TestDataFactory.createEntitlementRecords('Low Enhancement Process', account.Id, System.today(), lowSLA.Id, hours, True);
            
            case criticalCaseRecord = TestDataFactory.createEnhanceCaseRecords(account.Id, contact.Id, criticalEntitlement.Id, 'Critical', 'Open', True);
            case highCaseRecord = TestDataFactory.createEnhanceCaseRecords(account.Id, contact.Id, highEntitlement.Id, 'High', 'Open', True);
            case mediumCaseRecord = TestDataFactory.createEnhanceCaseRecords(account.Id, contact.Id, mediumEntitlement.Id, 'Medium', 'Open', True);
            case lowCaseRecord = TestDataFactory.createEnhanceCaseRecords(account.Id, contact.Id, lowEntitlement.Id, 'Low', 'Open', True);
            
            criticalCaseRecord.OwnerId = groupMap.get('Development').Id;
            criticalCaseRecord.SubStatus__c = 'Additional Information : YES';
            
            highCaseRecord.OwnerId = groupMap.get('Development').Id;
            highCaseRecord.SubStatus__c = 'Additional Information : YES';
            
            mediumCaseRecord.OwnerId = groupMap.get('Development').Id;
            mediumCaseRecord.SubStatus__c = 'Additional Information : YES';
            
            lowCaseRecord.OwnerId = groupMap.get('Development').Id;
            lowCaseRecord.SubStatus__c = 'Additional Information : YES';
            
            test.startTest();
            update criticalCaseRecord;
            update highCaseRecord;
            update mediumCaseRecord;
            update lowCaseRecord;
            test.stopTest();
            
            case updatedCriticalCs = [Select id,  OwnerId from case where id =: criticalCaseRecord.Id];
            case updatedHighCs = [Select id,  OwnerId from case where id =: highCaseRecord.Id];
            case updatedMediumCs = [Select id,  OwnerId from case where id =: mediumCaseRecord.Id];
            case updatedLowCs = [Select id,  OwnerId from case where id =: lowCaseRecord.Id];
            
            system.assertEquals(True,
                                caseSelector.matchOwner(updatedCriticalCs.OwnerId, Constants.QUEUE_DEVELOPMENT, groupMap, groupMemMap), 
                                'Case owner is not Development');
            
            system.assertEquals(True,
                                caseSelector.matchOwner(updatedHighCs.OwnerId, Constants.QUEUE_DEVELOPMENT, groupMap, groupMemMap), 
                                'Case owner is not Development');
            
            system.assertEquals(True,
                                caseSelector.matchOwner(updatedMediumCs.OwnerId, Constants.QUEUE_DEVELOPMENT, groupMap, groupMemMap), 
                                'Case owner is not Development');
            
            system.assertEquals(True,
                                caseSelector.matchOwner(updatedLowCs.OwnerId, Constants.QUEUE_DEVELOPMENT, groupMap, groupMemMap), 
                                'Case owner is not Development');
            
            
            List<CaseMilestone> cmsCritical = [select Id, completionDate from CaseMilestone cm where caseId = :updatedCriticalCs.Id and cm.MilestoneType.Name ='SRS/BRS : Needs Additional Information (CRITICAL)' and completionDate = Null];        
            List<CaseMilestone> cmsHigh = [select Id, completionDate from CaseMilestone cm where caseId = :updatedHighCs.Id and cm.MilestoneType.Name ='SRS/BRS : Needs Additional Information (HIGH)' and completionDate = Null];        
            List<CaseMilestone> cmsMedium = [select Id, completionDate from CaseMilestone cm where caseId = :updatedMediumCs.Id and cm.MilestoneType.Name ='SRS/BRS : Needs Additional Information (MEDIUM)' and completionDate = Null];        
            List<CaseMilestone> cmsLow = [select Id, completionDate from CaseMilestone cm where caseId = :updatedLowCs.Id and cm.MilestoneType.Name ='SRS/BRS : Needs Additional Information (LOW)' and completionDate = Null];        
            
            system.assertNotEquals(0, cmsCritical.size(), 'Critical Milestone Not attached');
            system.assertNotEquals(0, cmsHigh.size(), 'High Milestone Not attached');
            system.assertNotEquals(0, cmsMedium.size(), 'Medium Milestone Not attached');
            system.assertNotEquals(0, cmsLow.size(), 'Low Milestone Not attached');
        }
    }
    
    /*
* Method enhance_ProSpecial_Get_Information_Test
* @description : MSC 101-13 - Product Specialist get the required information asked by Development team. 
* Case is assigned to Development team. 
*/
    @isTest
    public static void enhance_ProSpecial_Get_Information_Test(){
        User queueUser = TestDataFactory.getGroupMemberId('Development');
        System.runAs(queueUser){
            prepareTestRecord();
            SlaProcess criticalSLA = TestDataFactory.getSlaProcessNames('Critical Enhancement Process');
            SlaProcess highSLA = TestDataFactory.getSlaProcessNames('High Enhancement Process');
            SlaProcess mediumSLA = TestDataFactory.getSlaProcessNames('Medium Enhancement Process');
            SlaProcess lowSLA = TestDataFactory.getSlaProcessNames('Low Enhancement Process');
            
            Entitlement criticalEntitlement = TestDataFactory.createEntitlementRecords('Critical Enhancement Process', account.Id, System.today(), criticalSLA.Id, hours, True);
            Entitlement highEntitlement = TestDataFactory.createEntitlementRecords('High Enhancement Process', account.Id, System.today(), highSLA.Id, hours, True);
            Entitlement mediumEntitlement = TestDataFactory.createEntitlementRecords('Medium Enhancement Process', account.Id, System.today(), mediumSLA.Id, hours, True);
            Entitlement lowEntitlement = TestDataFactory.createEntitlementRecords('Low Enhancement Process', account.Id, System.today(), lowSLA.Id, hours, True);
            
            case criticalCaseRecord = TestDataFactory.createEnhanceCaseRecords(account.Id, contact.Id, criticalEntitlement.Id, 'Critical', 'Open', True);
            case highCaseRecord = TestDataFactory.createEnhanceCaseRecords(account.Id, contact.Id, highEntitlement.Id, 'High', 'Open', True);
            case mediumCaseRecord = TestDataFactory.createEnhanceCaseRecords(account.Id, contact.Id, mediumEntitlement.Id, 'Medium', 'Open', True);
            case lowCaseRecord = TestDataFactory.createEnhanceCaseRecords(account.Id, contact.Id, lowEntitlement.Id, 'Low', 'Open', True);
            
            criticalCaseRecord.OwnerId = groupMap.get('Development').Id;
            criticalCaseRecord.SubStatus__c = 'Additional Information : NO';
            
            highCaseRecord.OwnerId = groupMap.get('Development').Id;
            highCaseRecord.SubStatus__c = 'Additional Information : NO';
            
            mediumCaseRecord.OwnerId = groupMap.get('Development').Id;
            mediumCaseRecord.SubStatus__c = 'Additional Information : NO';
            
            lowCaseRecord.OwnerId = groupMap.get('Development').Id;
            lowCaseRecord.SubStatus__c = 'Additional Information : NO';
            
            test.startTest();
            update criticalCaseRecord;
            update highCaseRecord;
            update mediumCaseRecord;
            update lowCaseRecord;
            test.stopTest();
            
            case updatedCriticalCs = [Select id,  OwnerId from case where id =: criticalCaseRecord.Id];
            case updatedHighCs = [Select id,  OwnerId from case where id =: highCaseRecord.Id];
            case updatedMediumCs = [Select id,  OwnerId from case where id =: mediumCaseRecord.Id];
            case updatedLowCs = [Select id,  OwnerId from case where id =: lowCaseRecord.Id];
            
            system.assertEquals(True,
                                caseSelector.matchOwner(updatedCriticalCs.OwnerId, Constants.QUEUE_DEVELOPMENT, groupMap, groupMemMap), 
                                'Case owner is not Development');
            
            system.assertEquals(True,
                                caseSelector.matchOwner(updatedHighCs.OwnerId, Constants.QUEUE_DEVELOPMENT, groupMap, groupMemMap), 
                                'Case owner is not Development');
            
            system.assertEquals(True,
                                caseSelector.matchOwner(updatedMediumCs.OwnerId, Constants.QUEUE_DEVELOPMENT, groupMap, groupMemMap), 
                                'Case owner is not Development');
            
            system.assertEquals(True,
                                caseSelector.matchOwner(updatedLowCs.OwnerId, Constants.QUEUE_DEVELOPMENT, groupMap, groupMemMap), 
                                'Case owner is not Development');
            
            
            List<CaseMilestone> cmsCritical = [select Id, completionDate from CaseMilestone cm where caseId = :updatedCriticalCs.Id and cm.MilestoneType.Name ='SRS/BRS: Revision (CRITICAL)' and completionDate = Null];        
            List<CaseMilestone> cmsHigh = [select Id, completionDate from CaseMilestone cm where caseId = :updatedHighCs.Id and cm.MilestoneType.Name ='SRS/BRS: Revision (HIGH)' and completionDate = Null];        
            List<CaseMilestone> cmsMedium = [select Id, completionDate from CaseMilestone cm where caseId = :updatedMediumCs.Id and cm.MilestoneType.Name ='SRS/BRS: Revision (MEDIUM)' and completionDate = Null];        
            List<CaseMilestone> cmsLow = [select Id, completionDate from CaseMilestone cm where caseId = :updatedLowCs.Id and cm.MilestoneType.Name ='SRS/BRS: Revision (LOW)' and completionDate = Null];        
            
            system.assertNotEquals(0, cmsCritical.size(), 'Critical Milestone Not attached');
            system.assertNotEquals(0, cmsHigh.size(), 'High Milestone Not attached');
            system.assertNotEquals(0, cmsMedium.size(), 'Medium Milestone Not attached');
            system.assertNotEquals(0, cmsLow.size(), 'Low Milestone Not attached');
        }
    }
    
    /*
    * Method enhance_Dev_Prepare_GapDocument_Test
    * @description : MSC 101-12 - Development team prepares the Gap Document.
    * Case is assigned to Account Manager. 
    */
    @isTest
    public static void enhance_Dev_Prepare_GapDocument_Test(){
        User queueUser = TestDataFactory.getGroupMemberId('Development');
        System.runAs(queueUser){
            prepareTestRecord();
            SlaProcess criticalSLA = TestDataFactory.getSlaProcessNames('Critical Enhancement Process');
            SlaProcess highSLA = TestDataFactory.getSlaProcessNames('High Enhancement Process');
            SlaProcess mediumSLA = TestDataFactory.getSlaProcessNames('Medium Enhancement Process');
            SlaProcess lowSLA = TestDataFactory.getSlaProcessNames('Low Enhancement Process');
            
            Entitlement criticalEntitlement = TestDataFactory.createEntitlementRecords('Critical Enhancement Process', account.Id, System.today(), criticalSLA.Id, hours, True);
            Entitlement highEntitlement = TestDataFactory.createEntitlementRecords('High Enhancement Process', account.Id, System.today(), highSLA.Id, hours, True);
            Entitlement mediumEntitlement = TestDataFactory.createEntitlementRecords('Medium Enhancement Process', account.Id, System.today(), mediumSLA.Id, hours, True);
            Entitlement lowEntitlement = TestDataFactory.createEntitlementRecords('Low Enhancement Process', account.Id, System.today(), lowSLA.Id, hours, True);
            
            case criticalCaseRecord = TestDataFactory.createEnhanceCaseRecords(account.Id, contact.Id, criticalEntitlement.Id, 'Critical', 'Open', True);
            case highCaseRecord = TestDataFactory.createEnhanceCaseRecords(account.Id, contact.Id, highEntitlement.Id, 'High', 'Open', True);
            case mediumCaseRecord = TestDataFactory.createEnhanceCaseRecords(account.Id, contact.Id, mediumEntitlement.Id, 'Medium', 'Open', True);
            case lowCaseRecord = TestDataFactory.createEnhanceCaseRecords(account.Id, contact.Id, lowEntitlement.Id, 'Low', 'Open', True);
            
            criticalCaseRecord.OwnerId = groupMap.get('Development').Id;
            criticalCaseRecord.SubStatus__c = 'Gap Document is completed';
            
            highCaseRecord.OwnerId = groupMap.get('Development').Id;
            highCaseRecord.SubStatus__c = 'Gap Document is completed';
            
            mediumCaseRecord.OwnerId = groupMap.get('Development').Id;
            mediumCaseRecord.SubStatus__c = 'Gap Document is completed';
            
            lowCaseRecord.OwnerId = groupMap.get('Development').Id;
            lowCaseRecord.SubStatus__c = 'Gap Document is completed';
            
            test.startTest();
            update criticalCaseRecord;
            update highCaseRecord;
            update mediumCaseRecord;
            update lowCaseRecord;
            test.stopTest();
            
            case updatedCriticalCs = [Select id,  OwnerId from case where id =: criticalCaseRecord.Id];
            case updatedHighCs = [Select id,  OwnerId from case where id =: highCaseRecord.Id];
            case updatedMediumCs = [Select id,  OwnerId from case where id =: mediumCaseRecord.Id];
            case updatedLowCs = [Select id,  OwnerId from case where id =: lowCaseRecord.Id];
            
            system.assertEquals(groupMap.get('Account Manager').Id, updatedCriticalCs.OwnerId, 'Case owner is not Account Manager');
            system.assertEquals(groupMap.get('Account Manager').Id, updatedHighCs.OwnerId, 'Case owner is not Account Manager');
            system.assertEquals(groupMap.get('Account Manager').Id, updatedMediumCs.OwnerId, 'Case owner is not Account Manager');
            system.assertEquals(groupMap.get('Account Manager').Id, updatedLowCs.OwnerId, 'Case owner is not Account Manager');
            
            List<CaseMilestone> cmsCritical = [select Id, completionDate from CaseMilestone cm where caseId = :updatedCriticalCs.Id and cm.MilestoneType.Name ='Work Order Creation: Critical' and completionDate = Null];        
            List<CaseMilestone> cmsHigh = [select Id, completionDate from CaseMilestone cm where caseId = :updatedHighCs.Id and cm.MilestoneType.Name ='Work Order Creation: High' and completionDate = Null];        
            List<CaseMilestone> cmsMedium = [select Id, completionDate from CaseMilestone cm where caseId = :updatedMediumCs.Id and cm.MilestoneType.Name ='Work Order Creation: Medium' and completionDate = Null];        
            List<CaseMilestone> cmsLow = [select Id, completionDate from CaseMilestone cm where caseId = :updatedLowCs.Id and cm.MilestoneType.Name ='Work Order Creation: Low' and completionDate = Null];        
            
            system.assertNotEquals(0, cmsCritical.size(), 'Critical Milestone Not attached');
            system.assertNotEquals(0, cmsHigh.size(), 'High Milestone Not attached');
            system.assertNotEquals(0, cmsMedium.size(), 'Medium Milestone Not attached');
            system.assertNotEquals(0, cmsLow.size(), 'Low Milestone Not attached');
        }
    }
    
    /*
    * Method enhance_AM_Prepare_WorkOrder_Test
    * @description : MSC 101-14 - Account Manager (AM) prepares the Work Order.
    * Case is assigned to Product Specialist. 
    */
    @isTest
    public static void enhance_AM_Prepare_WorkOrder_Test(){
        User queueUser = TestDataFactory.getGroupMemberId('Account Manager');
        System.runAs(queueUser){
            prepareTestRecord();
            SlaProcess criticalSLA = TestDataFactory.getSlaProcessNames('Critical Enhancement Process');
            SlaProcess highSLA = TestDataFactory.getSlaProcessNames('High Enhancement Process');
            SlaProcess mediumSLA = TestDataFactory.getSlaProcessNames('Medium Enhancement Process');
            SlaProcess lowSLA = TestDataFactory.getSlaProcessNames('Low Enhancement Process');
            
            Entitlement criticalEntitlement = TestDataFactory.createEntitlementRecords('Critical Enhancement Process', account.Id, System.today(), criticalSLA.Id, hours, True);
            Entitlement highEntitlement = TestDataFactory.createEntitlementRecords('High Enhancement Process', account.Id, System.today(), highSLA.Id, hours, True);
            Entitlement mediumEntitlement = TestDataFactory.createEntitlementRecords('Medium Enhancement Process', account.Id, System.today(), mediumSLA.Id, hours, True);
            Entitlement lowEntitlement = TestDataFactory.createEntitlementRecords('Low Enhancement Process', account.Id, System.today(), lowSLA.Id, hours, True);
            
            case criticalCaseRecord = TestDataFactory.createEnhanceCaseRecords(account.Id, contact.Id, criticalEntitlement.Id, 'Critical', 'Open', True);
            case highCaseRecord = TestDataFactory.createEnhanceCaseRecords(account.Id, contact.Id, highEntitlement.Id, 'High', 'Open', True);
            case mediumCaseRecord = TestDataFactory.createEnhanceCaseRecords(account.Id, contact.Id, mediumEntitlement.Id, 'Medium', 'Open', True);
            case lowCaseRecord = TestDataFactory.createEnhanceCaseRecords(account.Id, contact.Id, lowEntitlement.Id, 'Low', 'Open', True);
            
            criticalCaseRecord.Subject = 'Critical Case';
            criticalCaseRecord.OwnerId = groupMap.get('Account Manager').Id;
            criticalCaseRecord.SubStatus__c = 'Work Order Created : YES';
            
            highCaseRecord.Subject = 'High Case';
            highCaseRecord.OwnerId = groupMap.get('Account Manager').Id;
            highCaseRecord.SubStatus__c = 'Work Order Created : YES';
            
            mediumCaseRecord.Subject = 'Medium Case';
            mediumCaseRecord.OwnerId = groupMap.get('Account Manager').Id;
            mediumCaseRecord.SubStatus__c = 'Work Order Created : YES';
            
            lowCaseRecord.Subject = 'Low Case';
            lowCaseRecord.OwnerId = groupMap.get('Account Manager').Id;
            lowCaseRecord.SubStatus__c = 'Work Order Created : YES';
            
            test.startTest();
            update criticalCaseRecord;
            update highCaseRecord;
            update mediumCaseRecord;
            update lowCaseRecord;
            test.stopTest();
            
            case updatedCriticalCs = [Select id,  OwnerId from case where id =: criticalCaseRecord.Id];
            case updatedHighCs = [Select id,  OwnerId from case where id =: highCaseRecord.Id];
            case updatedMediumCs = [Select id,  OwnerId from case where id =: mediumCaseRecord.Id];
            case updatedLowCs = [Select id,  OwnerId from case where id =: lowCaseRecord.Id];
            
            system.assertEquals(groupMap.get('Product Specialist').Id, updatedCriticalCs.OwnerId, 'Case owner is not Product Specialist');
            system.assertEquals(groupMap.get('Product Specialist').Id, updatedHighCs.OwnerId, 'Case owner is not Product Specialist');
            system.assertEquals(groupMap.get('Product Specialist').Id, updatedMediumCs.OwnerId, 'Case owner is not Product Specialist');
            system.assertEquals(groupMap.get('Product Specialist').Id, updatedLowCs.OwnerId, 'Case owner is not Product Specialist');
            
            List<CaseMilestone> cmsCritical = [select Id, completionDate from CaseMilestone cm where caseId = :updatedCriticalCs.Id and cm.MilestoneType.Name ='Gap Document and Work Order : Review (CRITICAL)' and completionDate = Null];        
            List<CaseMilestone> cmsHigh = [select Id, completionDate from CaseMilestone cm where caseId = :updatedHighCs.Id and cm.MilestoneType.Name ='Gap Document and Work Order : Review (HIGH)' and completionDate = Null];        
            List<CaseMilestone> cmsMedium = [select Id, completionDate from CaseMilestone cm where caseId = :updatedMediumCs.Id and cm.MilestoneType.Name ='Gap Document and Work Order : Review (MEDIUM)' and completionDate = Null];        
            List<CaseMilestone> cmsLow = [select Id, completionDate from CaseMilestone cm where caseId = :updatedLowCs.Id and cm.MilestoneType.Name ='Gap Document and Work Order : Review (LOW)' and completionDate = Null];        
            
            system.assertNotEquals(0, cmsCritical.size(), 'Critical Milestone Not attached');
            system.assertNotEquals(0, cmsHigh.size(), 'High Milestone Not attached');
            system.assertNotEquals(0, cmsMedium.size(), 'Medium Milestone Not attached');
            system.assertNotEquals(0, cmsLow.size(), 'Low Milestone Not attached');
        }
    }
    
    /*
    * Method enhance_Man_Days_Impacted_Test
    * @description : MSC 101-15 - Product Specialist receives a signed Gap Document and manday is impacted
    * Case is assigned to Development. 
    */
    @isTest
    public static void enhance_Man_Days_Impacted_Test(){
        User queueUser = TestDataFactory.getGroupMemberId('Product Specialist');
        System.runAs(queueUser){
            prepareTestRecord();
            SlaProcess criticalSLA = TestDataFactory.getSlaProcessNames('Critical Enhancement Process');
            SlaProcess highSLA = TestDataFactory.getSlaProcessNames('High Enhancement Process');
            SlaProcess mediumSLA = TestDataFactory.getSlaProcessNames('Medium Enhancement Process');
            SlaProcess lowSLA = TestDataFactory.getSlaProcessNames('Low Enhancement Process');
            
            Entitlement criticalEntitlement = TestDataFactory.createEntitlementRecords('Critical Enhancement Process', account.Id, System.today(), criticalSLA.Id, hours, True);
            Entitlement highEntitlement = TestDataFactory.createEntitlementRecords('High Enhancement Process', account.Id, System.today(), highSLA.Id, hours, True);
            Entitlement mediumEntitlement = TestDataFactory.createEntitlementRecords('Medium Enhancement Process', account.Id, System.today(), mediumSLA.Id, hours, True);
            Entitlement lowEntitlement = TestDataFactory.createEntitlementRecords('Low Enhancement Process', account.Id, System.today(), lowSLA.Id, hours, True);
            
            case criticalCaseRecord = TestDataFactory.createEnhanceCaseRecords(account.Id, contact.Id, criticalEntitlement.Id, 'Critical', 'Open', True);
            case highCaseRecord = TestDataFactory.createEnhanceCaseRecords(account.Id, contact.Id, highEntitlement.Id, 'High', 'Open', True);
            case mediumCaseRecord = TestDataFactory.createEnhanceCaseRecords(account.Id, contact.Id, mediumEntitlement.Id, 'Medium', 'Open', True);
            case lowCaseRecord = TestDataFactory.createEnhanceCaseRecords(account.Id, contact.Id, lowEntitlement.Id, 'Low', 'Open', True);
            
            criticalCaseRecord.OwnerId = groupMap.get('Product Specialist').Id;
            criticalCaseRecord.SubStatus__c = 'Gap Document Creation / Update';
            
            highCaseRecord.OwnerId = groupMap.get('Product Specialist').Id;
            highCaseRecord.SubStatus__c = 'Gap Document Creation / Update';
            
            mediumCaseRecord.OwnerId = groupMap.get('Product Specialist').Id;
            mediumCaseRecord.SubStatus__c = 'Gap Document Creation / Update';
            
            lowCaseRecord.OwnerId = groupMap.get('Product Specialist').Id;
            lowCaseRecord.SubStatus__c = 'Gap Document Creation / Update';
            
            test.startTest();
            update criticalCaseRecord;
            update highCaseRecord;
            update mediumCaseRecord;
            update lowCaseRecord;
            test.stopTest();
            
            case updatedCriticalCs = [Select id,  OwnerId from case where id =: criticalCaseRecord.Id];
            case updatedHighCs = [Select id,  OwnerId from case where id =: highCaseRecord.Id];
            case updatedMediumCs = [Select id,  OwnerId from case where id =: mediumCaseRecord.Id];
            case updatedLowCs = [Select id,  OwnerId from case where id =: lowCaseRecord.Id];
            
            system.assertEquals(groupMap.get('Development').Id, updatedCriticalCs.OwnerId, 'Case owner is not Development');
            system.assertEquals(groupMap.get('Development').Id, updatedHighCs.OwnerId, 'Case owner is not Development');
            system.assertEquals(groupMap.get('Development').Id, updatedMediumCs.OwnerId, 'Case owner is not Development');
            system.assertEquals(groupMap.get('Development').Id, updatedLowCs.OwnerId, 'Case owner is not Development');
            
            List<CaseMilestone> cmsCritical = [select Id, completionDate from CaseMilestone cm where caseId = :updatedCriticalCs.Id and cm.MilestoneType.Name ='SRS/BRS: Revision (CRITICAL)' and completionDate = Null];        
            List<CaseMilestone> cmsHigh = [select Id, completionDate from CaseMilestone cm where caseId = :updatedHighCs.Id and cm.MilestoneType.Name ='SRS/BRS: Revision (HIGH)' and completionDate = Null];        
            List<CaseMilestone> cmsMedium = [select Id, completionDate from CaseMilestone cm where caseId = :updatedMediumCs.Id and cm.MilestoneType.Name ='SRS/BRS: Revision (MEDIUM)' and completionDate = Null];        
            List<CaseMilestone> cmsLow = [select Id, completionDate from CaseMilestone cm where caseId = :updatedLowCs.Id and cm.MilestoneType.Name ='SRS/BRS: Revision (LOW)' and completionDate = Null];        
            
            system.assertNotEquals(0, cmsCritical.size(), 'Critical Milestone Not attached');
            system.assertNotEquals(0, cmsHigh.size(), 'High Milestone Not attached');
            system.assertNotEquals(0, cmsMedium.size(), 'Medium Milestone Not attached');
            system.assertNotEquals(0, cmsLow.size(), 'Low Milestone Not attached');
        }
    }
    
    /*
    * Method enhance_Dev_Again_Prepare_GapDocument_Test
    * @description : MSC 101-12 - Development team prepares the Gap Document.
    * Case is assigned to Account Manager. 
    */
    @isTest
    public static void enhance_Dev_Again_Prepare_GapDocument_Test(){
        User queueUser = TestDataFactory.getGroupMemberId('Development');
        System.runAs(queueUser){
            prepareTestRecord();
            SlaProcess criticalSLA = TestDataFactory.getSlaProcessNames('Critical Enhancement Process');
            SlaProcess highSLA = TestDataFactory.getSlaProcessNames('High Enhancement Process');
            SlaProcess mediumSLA = TestDataFactory.getSlaProcessNames('Medium Enhancement Process');
            SlaProcess lowSLA = TestDataFactory.getSlaProcessNames('Low Enhancement Process');
            
            Entitlement criticalEntitlement = TestDataFactory.createEntitlementRecords('Critical Enhancement Process', account.Id, System.today(), criticalSLA.Id, hours, True);
            Entitlement highEntitlement = TestDataFactory.createEntitlementRecords('High Enhancement Process', account.Id, System.today(), highSLA.Id, hours, True);
            Entitlement mediumEntitlement = TestDataFactory.createEntitlementRecords('Medium Enhancement Process', account.Id, System.today(), mediumSLA.Id, hours, True);
            Entitlement lowEntitlement = TestDataFactory.createEntitlementRecords('Low Enhancement Process', account.Id, System.today(), lowSLA.Id, hours, True);
            
            case criticalCaseRecord = TestDataFactory.createEnhanceCaseRecords(account.Id, contact.Id, criticalEntitlement.Id, 'Critical', 'Open', True);
            case highCaseRecord = TestDataFactory.createEnhanceCaseRecords(account.Id, contact.Id, highEntitlement.Id, 'High', 'Open', True);
            case mediumCaseRecord = TestDataFactory.createEnhanceCaseRecords(account.Id, contact.Id, mediumEntitlement.Id, 'Medium', 'Open', True);
            case lowCaseRecord = TestDataFactory.createEnhanceCaseRecords(account.Id, contact.Id, lowEntitlement.Id, 'Low', 'Open', True);
            
            criticalCaseRecord.OwnerId = groupMap.get('Development').Id;
            criticalCaseRecord.SubStatus__c = 'Gap Document is completed';
            
            highCaseRecord.OwnerId = groupMap.get('Development').Id;
            highCaseRecord.SubStatus__c = 'Gap Document is completed';
            
            mediumCaseRecord.OwnerId = groupMap.get('Development').Id;
            mediumCaseRecord.SubStatus__c = 'Gap Document is completed';
            
            lowCaseRecord.OwnerId = groupMap.get('Development').Id;
            lowCaseRecord.SubStatus__c = 'Gap Document is completed';
            
            test.startTest();
            update criticalCaseRecord;
            update highCaseRecord;
            update mediumCaseRecord;
            update lowCaseRecord;
            test.stopTest();
            
            case updatedCriticalCs = [Select id,  OwnerId from case where id =: criticalCaseRecord.Id];
            case updatedHighCs = [Select id,  OwnerId from case where id =: highCaseRecord.Id];
            case updatedMediumCs = [Select id,  OwnerId from case where id =: mediumCaseRecord.Id];
            case updatedLowCs = [Select id,  OwnerId from case where id =: lowCaseRecord.Id];
            
            system.assertEquals(groupMap.get('Account Manager').Id, updatedCriticalCs.OwnerId, 'Case owner is not Account Manager');
            system.assertEquals(groupMap.get('Account Manager').Id, updatedHighCs.OwnerId, 'Case owner is not Account Manager');
            system.assertEquals(groupMap.get('Account Manager').Id, updatedMediumCs.OwnerId, 'Case owner is not Account Manager');
            system.assertEquals(groupMap.get('Account Manager').Id, updatedLowCs.OwnerId, 'Case owner is not Account Manager');
            
            List<CaseMilestone> cmsCritical = [select Id, completionDate from CaseMilestone cm where caseId = :updatedCriticalCs.Id and cm.MilestoneType.Name ='Work Order Creation: Critical' and completionDate = Null];        
            List<CaseMilestone> cmsHigh = [select Id, completionDate from CaseMilestone cm where caseId = :updatedHighCs.Id and cm.MilestoneType.Name ='Work Order Creation: High' and completionDate = Null];        
            List<CaseMilestone> cmsMedium = [select Id, completionDate from CaseMilestone cm where caseId = :updatedMediumCs.Id and cm.MilestoneType.Name ='Work Order Creation: Medium' and completionDate = Null];        
            List<CaseMilestone> cmsLow = [select Id, completionDate from CaseMilestone cm where caseId = :updatedLowCs.Id and cm.MilestoneType.Name ='Work Order Creation: Low' and completionDate = Null];        
            
            system.assertNotEquals(0, cmsCritical.size(), 'Critical Milestone Not attached');
            system.assertNotEquals(0, cmsHigh.size(), 'High Milestone Not attached');
            system.assertNotEquals(0, cmsMedium.size(), 'Medium Milestone Not attached');
            system.assertNotEquals(0, cmsLow.size(), 'Low Milestone Not attached');
        }
    }
    
    /*
    * Method enhance_AM_Again_Prepare_WorkOrder_Test
    * @description : MSC 101-14 - Account Manager (AM) prepares the Work Order.
    * Case is assigned to Product Specialist. 
    */
    @isTest
    public static void enhance_AM_Again_Prepare_WorkOrder_Test(){
        User queueUser = TestDataFactory.getGroupMemberId('Account Manager');
        System.runAs(queueUser){
            prepareTestRecord();
            SlaProcess criticalSLA = TestDataFactory.getSlaProcessNames('Critical Enhancement Process');
            SlaProcess highSLA = TestDataFactory.getSlaProcessNames('High Enhancement Process');
            SlaProcess mediumSLA = TestDataFactory.getSlaProcessNames('Medium Enhancement Process');
            SlaProcess lowSLA = TestDataFactory.getSlaProcessNames('Low Enhancement Process');
            
            Entitlement criticalEntitlement = TestDataFactory.createEntitlementRecords('Critical Enhancement Process', account.Id, System.today(), criticalSLA.Id, hours, True);
            Entitlement highEntitlement = TestDataFactory.createEntitlementRecords('High Enhancement Process', account.Id, System.today(), highSLA.Id, hours, True);
            Entitlement mediumEntitlement = TestDataFactory.createEntitlementRecords('Medium Enhancement Process', account.Id, System.today(), mediumSLA.Id, hours, True);
            Entitlement lowEntitlement = TestDataFactory.createEntitlementRecords('Low Enhancement Process', account.Id, System.today(), lowSLA.Id, hours, True);
            
            case criticalCaseRecord = TestDataFactory.createEnhanceCaseRecords(account.Id, contact.Id, criticalEntitlement.Id, 'Critical', 'Open', True);
            case highCaseRecord = TestDataFactory.createEnhanceCaseRecords(account.Id, contact.Id, highEntitlement.Id, 'High', 'Open', True);
            case mediumCaseRecord = TestDataFactory.createEnhanceCaseRecords(account.Id, contact.Id, mediumEntitlement.Id, 'Medium', 'Open', True);
            case lowCaseRecord = TestDataFactory.createEnhanceCaseRecords(account.Id, contact.Id, lowEntitlement.Id, 'Low', 'Open', True);
            
            criticalCaseRecord.Subject = 'Critical Case';
            criticalCaseRecord.OwnerId = groupMap.get('Account Manager').Id;
            criticalCaseRecord.SubStatus__c = 'Work Order Created : YES';
            
            highCaseRecord.Subject = 'High Case';
            highCaseRecord.OwnerId = groupMap.get('Account Manager').Id;
            highCaseRecord.SubStatus__c = 'Work Order Created : YES';
            
            mediumCaseRecord.Subject = 'Medium Case';
            mediumCaseRecord.OwnerId = groupMap.get('Account Manager').Id;
            mediumCaseRecord.SubStatus__c = 'Work Order Created : YES';
            
            lowCaseRecord.Subject = 'Low Case';
            lowCaseRecord.OwnerId = groupMap.get('Account Manager').Id;
            lowCaseRecord.SubStatus__c = 'Work Order Created : YES';
            
            test.startTest();
            update criticalCaseRecord;
            update highCaseRecord;
            update mediumCaseRecord;
            update lowCaseRecord;
            test.stopTest();
            
            case updatedCriticalCs = [Select id,  OwnerId from case where id =: criticalCaseRecord.Id];
            case updatedHighCs = [Select id,  OwnerId from case where id =: highCaseRecord.Id];
            case updatedMediumCs = [Select id,  OwnerId from case where id =: mediumCaseRecord.Id];
            case updatedLowCs = [Select id,  OwnerId from case where id =: lowCaseRecord.Id];
            
            system.assertEquals(groupMap.get('Product Specialist').Id, updatedCriticalCs.OwnerId, 'Case owner is not Product Specialist');
            system.assertEquals(groupMap.get('Product Specialist').Id, updatedHighCs.OwnerId, 'Case owner is not Product Specialist');
            system.assertEquals(groupMap.get('Product Specialist').Id, updatedMediumCs.OwnerId, 'Case owner is not Product Specialist');
            system.assertEquals(groupMap.get('Product Specialist').Id, updatedLowCs.OwnerId, 'Case owner is not Product Specialist');
            
            List<CaseMilestone> cmsCritical = [select Id, completionDate from CaseMilestone cm where caseId = :updatedCriticalCs.Id and cm.MilestoneType.Name ='Gap Document and Work Order : Review (CRITICAL)' and completionDate = Null];        
            List<CaseMilestone> cmsHigh = [select Id, completionDate from CaseMilestone cm where caseId = :updatedHighCs.Id and cm.MilestoneType.Name ='Gap Document and Work Order : Review (HIGH)' and completionDate = Null];        
            List<CaseMilestone> cmsMedium = [select Id, completionDate from CaseMilestone cm where caseId = :updatedMediumCs.Id and cm.MilestoneType.Name ='Gap Document and Work Order : Review (MEDIUM)' and completionDate = Null];        
            List<CaseMilestone> cmsLow = [select Id, completionDate from CaseMilestone cm where caseId = :updatedLowCs.Id and cm.MilestoneType.Name ='Gap Document and Work Order : Review (LOW)' and completionDate = Null];        
            
            system.assertNotEquals(0, cmsCritical.size(), 'Critical Milestone Not attached');
            system.assertNotEquals(0, cmsHigh.size(), 'High Milestone Not attached');
            system.assertNotEquals(0, cmsMedium.size(), 'Medium Milestone Not attached');
            system.assertNotEquals(0, cmsLow.size(), 'Low Milestone Not attached');
        }
    }
    
    /*
    * Method enhance_Man_Days_Not_Impacted_Test
    * @description : MSC 101-15 - Product Specialist receives a signed Gap Document and manday is not impacted
    * Case is assigned to Development to create FRS. 
    */
    @isTest
    public static void enhance_Man_Days_Not_Impacted_Test(){
        User queueUser = TestDataFactory.getGroupMemberId('Product Specialist');
        System.runAs(queueUser){
            prepareTestRecord();
            SlaProcess criticalSLA = TestDataFactory.getSlaProcessNames('Critical Enhancement Process');
            SlaProcess highSLA = TestDataFactory.getSlaProcessNames('High Enhancement Process');
            SlaProcess mediumSLA = TestDataFactory.getSlaProcessNames('Medium Enhancement Process');
            SlaProcess lowSLA = TestDataFactory.getSlaProcessNames('Low Enhancement Process');
            
            Entitlement criticalEntitlement = TestDataFactory.createEntitlementRecords('Critical Enhancement Process', account.Id, System.today(), criticalSLA.Id, hours, True);
            Entitlement highEntitlement = TestDataFactory.createEntitlementRecords('High Enhancement Process', account.Id, System.today(), highSLA.Id, hours, True);
            Entitlement mediumEntitlement = TestDataFactory.createEntitlementRecords('Medium Enhancement Process', account.Id, System.today(), mediumSLA.Id, hours, True);
            Entitlement lowEntitlement = TestDataFactory.createEntitlementRecords('Low Enhancement Process', account.Id, System.today(), lowSLA.Id, hours, True);
            
            case criticalCaseRecord = TestDataFactory.createEnhanceCaseRecords(account.Id, contact.Id, criticalEntitlement.Id, 'Critical', 'Open', True);
            case highCaseRecord = TestDataFactory.createEnhanceCaseRecords(account.Id, contact.Id, highEntitlement.Id, 'High', 'Open', True);
            case mediumCaseRecord = TestDataFactory.createEnhanceCaseRecords(account.Id, contact.Id, mediumEntitlement.Id, 'Medium', 'Open', True);
            case lowCaseRecord = TestDataFactory.createEnhanceCaseRecords(account.Id, contact.Id, lowEntitlement.Id, 'Low', 'Open', True);
            
            criticalCaseRecord.OwnerId = groupMap.get('Product Specialist').Id;
            criticalCaseRecord.SubStatus__c = 'FRS Creation';
            
            highCaseRecord.OwnerId = groupMap.get('Product Specialist').Id;
            highCaseRecord.SubStatus__c = 'FRS Creation';
            
            mediumCaseRecord.OwnerId = groupMap.get('Product Specialist').Id;
            mediumCaseRecord.SubStatus__c = 'FRS Creation';
            
            lowCaseRecord.OwnerId = groupMap.get('Product Specialist').Id;
            lowCaseRecord.SubStatus__c = 'FRS Creation';
            
            test.startTest();
            update criticalCaseRecord;
            update highCaseRecord;
            update mediumCaseRecord;
            update lowCaseRecord;
            test.stopTest();
            
            case updatedCriticalCs = [Select id,  OwnerId from case where id =: criticalCaseRecord.Id];
            case updatedHighCs = [Select id,  OwnerId from case where id =: highCaseRecord.Id];
            case updatedMediumCs = [Select id,  OwnerId from case where id =: mediumCaseRecord.Id];
            case updatedLowCs = [Select id,  OwnerId from case where id =: lowCaseRecord.Id];
            
            system.assertEquals(groupMap.get('Development').Id, updatedCriticalCs.OwnerId, 'Case owner is not Development');
            system.assertEquals(groupMap.get('Development').Id, updatedHighCs.OwnerId, 'Case owner is not Development');
            system.assertEquals(groupMap.get('Development').Id, updatedMediumCs.OwnerId, 'Case owner is not Development');
            system.assertEquals(groupMap.get('Development').Id, updatedLowCs.OwnerId, 'Case owner is not Development');
            
            List<CaseMilestone> cmsCritical = [select Id, completionDate from CaseMilestone cm where caseId = :updatedCriticalCs.Id and cm.MilestoneType.Name ='FRS Creation (CRITICAL)' and completionDate = Null];        
            List<CaseMilestone> cmsHigh = [select Id, completionDate from CaseMilestone cm where caseId = :updatedHighCs.Id and cm.MilestoneType.Name ='FRS Creation (HIGH)' and completionDate = Null];        
            List<CaseMilestone> cmsMedium = [select Id, completionDate from CaseMilestone cm where caseId = :updatedMediumCs.Id and cm.MilestoneType.Name ='FRS Creation (MEDIUM)' and completionDate = Null];        
            List<CaseMilestone> cmsLow = [select Id, completionDate from CaseMilestone cm where caseId = :updatedLowCs.Id and cm.MilestoneType.Name ='FRS Creation (LOW)' and completionDate = Null];        
            
            system.assertNotEquals(0, cmsCritical.size(), 'Critical Milestone Not attached');
            system.assertNotEquals(0, cmsHigh.size(), 'High Milestone Not attached');
            system.assertNotEquals(0, cmsMedium.size(), 'Medium Milestone Not attached');
            system.assertNotEquals(0, cmsLow.size(), 'Low Milestone Not attached');
        }
    }
 
	/*
    * Method enhance_Dev_Creates_FRS_Test
    * @description : MSC 101-16 - Developer crates the FRS and send it to Product Specialist.
    * Case is assigned to Product Specialist. 
    */
    @isTest
    public static void enhance_Dev_Creates_FRS_Test(){
        User queueUser = TestDataFactory.getGroupMemberId('Development');
        System.runAs(queueUser){
            prepareTestRecord();
            SlaProcess criticalSLA = TestDataFactory.getSlaProcessNames('Critical Enhancement Process');
            SlaProcess highSLA = TestDataFactory.getSlaProcessNames('High Enhancement Process');
            SlaProcess mediumSLA = TestDataFactory.getSlaProcessNames('Medium Enhancement Process');
            SlaProcess lowSLA = TestDataFactory.getSlaProcessNames('Low Enhancement Process');
            
            Entitlement criticalEntitlement = TestDataFactory.createEntitlementRecords('Critical Enhancement Process', account.Id, System.today(), criticalSLA.Id, hours, True);
            Entitlement highEntitlement = TestDataFactory.createEntitlementRecords('High Enhancement Process', account.Id, System.today(), highSLA.Id, hours, True);
            Entitlement mediumEntitlement = TestDataFactory.createEntitlementRecords('Medium Enhancement Process', account.Id, System.today(), mediumSLA.Id, hours, True);
            Entitlement lowEntitlement = TestDataFactory.createEntitlementRecords('Low Enhancement Process', account.Id, System.today(), lowSLA.Id, hours, True);
            
            case criticalCaseRecord = TestDataFactory.createEnhanceCaseRecords(account.Id, contact.Id, criticalEntitlement.Id, 'Critical', 'Open', True);
            case highCaseRecord = TestDataFactory.createEnhanceCaseRecords(account.Id, contact.Id, highEntitlement.Id, 'High', 'Open', True);
            case mediumCaseRecord = TestDataFactory.createEnhanceCaseRecords(account.Id, contact.Id, mediumEntitlement.Id, 'Medium', 'Open', True);
            case lowCaseRecord = TestDataFactory.createEnhanceCaseRecords(account.Id, contact.Id, lowEntitlement.Id, 'Low', 'Open', True);
            
            criticalCaseRecord.OwnerId = groupMap.get('Development').Id;
            criticalCaseRecord.SubStatus__c = 'Awaiting FRS';
            
            highCaseRecord.OwnerId = groupMap.get('Development').Id;
            highCaseRecord.SubStatus__c = 'Awaiting FRS';
            
            mediumCaseRecord.OwnerId = groupMap.get('Development').Id;
            mediumCaseRecord.SubStatus__c = 'Awaiting FRS';
            
            lowCaseRecord.OwnerId = groupMap.get('Development').Id;
            lowCaseRecord.SubStatus__c = 'Awaiting FRS';
            
            test.startTest();
            update criticalCaseRecord;
            update highCaseRecord;
            update mediumCaseRecord;
            update lowCaseRecord;
            test.stopTest();
            
            case updatedCriticalCs = [Select id,  OwnerId from case where id =: criticalCaseRecord.Id];
            case updatedHighCs = [Select id,  OwnerId from case where id =: highCaseRecord.Id];
            case updatedMediumCs = [Select id,  OwnerId from case where id =: mediumCaseRecord.Id];
            case updatedLowCs = [Select id,  OwnerId from case where id =: lowCaseRecord.Id];
            
            system.assertEquals(groupMap.get('Product Specialist').Id, updatedCriticalCs.OwnerId, 'Case owner is not Product Specialist');
            system.assertEquals(groupMap.get('Product Specialist').Id, updatedHighCs.OwnerId, 'Case owner is not Product Specialist');
            system.assertEquals(groupMap.get('Product Specialist').Id, updatedMediumCs.OwnerId, 'Case owner is not Product Specialist');
            system.assertEquals(groupMap.get('Product Specialist').Id, updatedLowCs.OwnerId, 'Case owner is not Product Specialist');
            
            List<CaseMilestone> cmsCritical = [select Id, completionDate from CaseMilestone cm where caseId = :updatedCriticalCs.Id and cm.MilestoneType.Name ='Awaiting FRS (CRITICAL)' and completionDate = Null];        
            List<CaseMilestone> cmsHigh = [select Id, completionDate from CaseMilestone cm where caseId = :updatedHighCs.Id and cm.MilestoneType.Name ='Awaiting FRS (HIGH)' and completionDate = Null];        
            List<CaseMilestone> cmsMedium = [select Id, completionDate from CaseMilestone cm where caseId = :updatedMediumCs.Id and cm.MilestoneType.Name ='Awaiting FRS (MEDIUM)' and completionDate = Null];        
            List<CaseMilestone> cmsLow = [select Id, completionDate from CaseMilestone cm where caseId = :updatedLowCs.Id and cm.MilestoneType.Name ='Awaiting FRS (LOW)' and completionDate = Null];        
            
            system.assertNotEquals(0, cmsCritical.size(), 'Critical Milestone Not attached');
            system.assertNotEquals(0, cmsHigh.size(), 'High Milestone Not attached');
            system.assertNotEquals(0, cmsMedium.size(), 'Medium Milestone Not attached');
            system.assertNotEquals(0, cmsLow.size(), 'Low Milestone Not attached');
        }
    }
    
    /*
    * Method enhance_Awaitng_Development_Test
    * @description : MSC 101-35 - Product Specialist reviews FRS and decide that Development can be started.
    * Case is assigned to Development. 
    */
    @isTest
    public static void enhance_Awaitng_Development_Test(){
        User queueUser = TestDataFactory.getGroupMemberId('Product Specialist');
        System.runAs(queueUser){
            prepareTestRecord();
            SlaProcess criticalSLA = TestDataFactory.getSlaProcessNames('Critical Enhancement Process');
            SlaProcess highSLA = TestDataFactory.getSlaProcessNames('High Enhancement Process');
            SlaProcess mediumSLA = TestDataFactory.getSlaProcessNames('Medium Enhancement Process');
            SlaProcess lowSLA = TestDataFactory.getSlaProcessNames('Low Enhancement Process');
            
            Entitlement criticalEntitlement = TestDataFactory.createEntitlementRecords('Critical Enhancement Process', account.Id, System.today(), criticalSLA.Id, hours, True);
            Entitlement highEntitlement = TestDataFactory.createEntitlementRecords('High Enhancement Process', account.Id, System.today(), highSLA.Id, hours, True);
            Entitlement mediumEntitlement = TestDataFactory.createEntitlementRecords('Medium Enhancement Process', account.Id, System.today(), mediumSLA.Id, hours, True);
            Entitlement lowEntitlement = TestDataFactory.createEntitlementRecords('Low Enhancement Process', account.Id, System.today(), lowSLA.Id, hours, True);
            
            case criticalCaseRecord = TestDataFactory.createEnhanceCaseRecords(account.Id, contact.Id, criticalEntitlement.Id, 'Critical', 'Open', True);
            case highCaseRecord = TestDataFactory.createEnhanceCaseRecords(account.Id, contact.Id, highEntitlement.Id, 'High', 'Open', True);
            case mediumCaseRecord = TestDataFactory.createEnhanceCaseRecords(account.Id, contact.Id, mediumEntitlement.Id, 'Medium', 'Open', True);
            case lowCaseRecord = TestDataFactory.createEnhanceCaseRecords(account.Id, contact.Id, lowEntitlement.Id, 'Low', 'Open', True);
            
            criticalCaseRecord.OwnerId = groupMap.get('Product Specialist').Id;
            criticalCaseRecord.SubStatus__c = 'Awaiting Development';
            
            highCaseRecord.OwnerId = groupMap.get('Product Specialist').Id;
            highCaseRecord.SubStatus__c = 'Awaiting Development';
            
            mediumCaseRecord.OwnerId = groupMap.get('Product Specialist').Id;
            mediumCaseRecord.SubStatus__c = 'Awaiting Development';
            
            lowCaseRecord.OwnerId = groupMap.get('Product Specialist').Id;
            lowCaseRecord.SubStatus__c = 'Awaiting Development';
            
            test.startTest();
            update criticalCaseRecord;
            update highCaseRecord;
            update mediumCaseRecord;
            update lowCaseRecord;
            test.stopTest();
            
            case updatedCriticalCs = [Select id,  OwnerId from case where id =: criticalCaseRecord.Id];
            case updatedHighCs = [Select id,  OwnerId from case where id =: highCaseRecord.Id];
            case updatedMediumCs = [Select id,  OwnerId from case where id =: mediumCaseRecord.Id];
            case updatedLowCs = [Select id,  OwnerId from case where id =: lowCaseRecord.Id];
            
            system.assertEquals(groupMap.get('Development').Id, updatedCriticalCs.OwnerId, 'Case owner is not Development');
            system.assertEquals(groupMap.get('Development').Id, updatedHighCs.OwnerId, 'Case owner is not Development');
            system.assertEquals(groupMap.get('Development').Id, updatedMediumCs.OwnerId, 'Case owner is not Development');
            system.assertEquals(groupMap.get('Development').Id, updatedLowCs.OwnerId, 'Case owner is not Development');
            
            List<CaseMilestone> cmsCritical = [select Id, completionDate from CaseMilestone cm where caseId = :updatedCriticalCs.Id and cm.MilestoneType.Name ='Release Date added and Work Completed: CRITICAL' and completionDate = Null];        
            List<CaseMilestone> cmsHigh = [select Id, completionDate from CaseMilestone cm where caseId = :updatedHighCs.Id and cm.MilestoneType.Name ='Release Date added and Work Completed: HIGH' and completionDate = Null];        
            List<CaseMilestone> cmsMedium = [select Id, completionDate from CaseMilestone cm where caseId = :updatedMediumCs.Id and cm.MilestoneType.Name ='Release Date added and Work Completed: MEDIUM' and completionDate = Null];        
            List<CaseMilestone> cmsLow = [select Id, completionDate from CaseMilestone cm where caseId = :updatedLowCs.Id and cm.MilestoneType.Name ='Release Date added and Work Completed: LOW' and completionDate = Null];        
            
            system.assertNotEquals(0, cmsCritical.size(), 'Critical Milestone Not attached');
            system.assertNotEquals(0, cmsHigh.size(), 'High Milestone Not attached');
            system.assertNotEquals(0, cmsMedium.size(), 'Medium Milestone Not attached');
            system.assertNotEquals(0, cmsLow.size(), 'Low Milestone Not attached');
        }
    }
   
    /*
    * Method enhance_Pending_Verification_Test
    * @description : MSC 101-17 - Development complete the development, put release date and send it Product Specialist.
    * Case is assigned to Product Specialist. 
    */
    @isTest
    public static void enhance_Pending_Verification_Test(){
        User queueUser = TestDataFactory.getGroupMemberId('Product Specialist');
        System.runAs(queueUser){
            prepareTestRecord();
            SlaProcess criticalSLA = TestDataFactory.getSlaProcessNames('Critical Enhancement Process');
            SlaProcess highSLA = TestDataFactory.getSlaProcessNames('High Enhancement Process');
            SlaProcess mediumSLA = TestDataFactory.getSlaProcessNames('Medium Enhancement Process');
            SlaProcess lowSLA = TestDataFactory.getSlaProcessNames('Low Enhancement Process');
            
            Entitlement criticalEntitlement = TestDataFactory.createEntitlementRecords('Critical Enhancement Process', account.Id, System.today(), criticalSLA.Id, hours, True);
            Entitlement highEntitlement = TestDataFactory.createEntitlementRecords('High Enhancement Process', account.Id, System.today(), highSLA.Id, hours, True);
            Entitlement mediumEntitlement = TestDataFactory.createEntitlementRecords('Medium Enhancement Process', account.Id, System.today(), mediumSLA.Id, hours, True);
            Entitlement lowEntitlement = TestDataFactory.createEntitlementRecords('Low Enhancement Process', account.Id, System.today(), lowSLA.Id, hours, True);
            
            case criticalCaseRecord = TestDataFactory.createEnhanceCaseRecords(account.Id, contact.Id, criticalEntitlement.Id, 'Critical', 'Open', True);
            case highCaseRecord = TestDataFactory.createEnhanceCaseRecords(account.Id, contact.Id, highEntitlement.Id, 'High', 'Open', True);
            case mediumCaseRecord = TestDataFactory.createEnhanceCaseRecords(account.Id, contact.Id, mediumEntitlement.Id, 'Medium', 'Open', True);
            case lowCaseRecord = TestDataFactory.createEnhanceCaseRecords(account.Id, contact.Id, lowEntitlement.Id, 'Low', 'Open', True);
            
            criticalCaseRecord.OwnerId = groupMap.get('Development').Id;
            criticalCaseRecord.Release_Timeline_For_Enhancement__c = Date.Today();
            criticalCaseRecord.SubStatus__c = 'Pending Resolution Verification';
            
            highCaseRecord.OwnerId = groupMap.get('Development').Id;
            highCaseRecord.Release_Timeline_For_Enhancement__c = Date.Today();
            highCaseRecord.SubStatus__c = 'Pending Resolution Verification';
            
            mediumCaseRecord.OwnerId = groupMap.get('Development').Id;
            mediumCaseRecord.Release_Timeline_For_Enhancement__c = Date.Today();
            mediumCaseRecord.SubStatus__c = 'Pending Resolution Verification';
            
            lowCaseRecord.OwnerId = groupMap.get('Development').Id;
            lowCaseRecord.Release_Timeline_For_Enhancement__c = Date.Today();
            lowCaseRecord.SubStatus__c = 'Pending Resolution Verification';
            
            test.startTest();
            update criticalCaseRecord;
            update highCaseRecord;
            update mediumCaseRecord;
            update lowCaseRecord;
            test.stopTest();
            
            case updatedCriticalCs = [Select id,  OwnerId from case where id =: criticalCaseRecord.Id];
            case updatedHighCs = [Select id,  OwnerId from case where id =: highCaseRecord.Id];
            case updatedMediumCs = [Select id,  OwnerId from case where id =: mediumCaseRecord.Id];
            case updatedLowCs = [Select id,  OwnerId from case where id =: lowCaseRecord.Id];
            
            system.assertEquals(True,
                                caseSelector.matchOwner(updatedCriticalCs.OwnerId, Constants.QUEUE_PRODUCT_SPECIALIST, groupMap, groupMemMap), 
                                'Case owner is not Product Specialist');
            
            system.assertEquals(True,
                                caseSelector.matchOwner(updatedHighCs.OwnerId, Constants.QUEUE_PRODUCT_SPECIALIST, groupMap, groupMemMap), 
                                'Case owner is not Product Specialist');
            
            system.assertEquals(True,
                                caseSelector.matchOwner(updatedMediumCs.OwnerId, Constants.QUEUE_PRODUCT_SPECIALIST, groupMap, groupMemMap), 
                                'Case owner is not Product Specialist');
            
            system.assertEquals(True,
                                caseSelector.matchOwner(updatedLowCs.OwnerId, Constants.QUEUE_PRODUCT_SPECIALIST, groupMap, groupMemMap), 
                                'Case owner is not Product Specialist');
            
            List<CaseMilestone> cmsCritical = [select Id, completionDate from CaseMilestone cm where caseId = :updatedCriticalCs.Id and completionDate = Null];        
            List<CaseMilestone> cmsHigh = [select Id, completionDate from CaseMilestone cm where caseId = :updatedHighCs.Id and completionDate = Null];        
            List<CaseMilestone> cmsMedium = [select Id, completionDate from CaseMilestone cm where caseId = :updatedMediumCs.Id and completionDate = Null];        
            List<CaseMilestone> cmsLow = [select Id, completionDate from CaseMilestone cm where caseId = :updatedLowCs.Id and completionDate = Null];        
            
            system.assertEquals(0, cmsCritical.size(), 'Previuos Critical Milestone Not closed');
            system.assertEquals(0, cmsHigh.size(), 'Previuos High Milestone Not closed');
            system.assertEquals(0, cmsMedium.size(), 'Previuos Medium Milestone Not closed');
            system.assertEquals(0, cmsLow.size(), 'Previuos Low Milestone Not closed');
        }
    }
    
}