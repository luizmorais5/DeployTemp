@isTest
public with sharing class TestDataFactory {
    
    public static Id enhanceCaseRecordTypeId = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByName().get('Enhancements').getRecordTypeId();
    public static Id hotfixCaseRecordTypeId = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByName().get('Hotfix').getRecordTypeId();
    public static Id clientCaseRecordTypeId = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByName().get('Client Page Layout').getRecordTypeId();
    
    public static User createUser1(){ 
        //Create portal account owner
        UserRole portalRole = [Select Id From UserRole Where PortalType = 'None' Limit 1];
        Profile profile1 = [Select Id from Profile where name = 'System Administrator'];
        User portalAccountOwner1 = new User(
            UserRoleId = portalRole.Id,
            ProfileId = profile1.Id,
            Username = System.now().millisecond() + 'test2@test.com',
            Alias = 'batman',
            Email='bruce.wayne@wayneenterprises.com',
            EmailEncodingKey='UTF-8',
            Firstname='Bruce',
            Lastname='Wayne',
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US',
            TimeZoneSidKey='America/Chicago'
        );
        Database.insert(portalAccountOwner1);

        //Create portal account owner
        //UserRole portalRole = [Select Id From UserRole Where PortalType = 'CustomerPortal' and DeveloperName = 'FidelityBankBahamasLtdCustomerUser' Limit 1];
       // System.debug('portalRole::'+portalRole.ID);
        Profile profile2 = [Select Id from Profile where name = 'MCS Customer Community Plus User'];
        System.debug('profile1::'+profile1.ID);
        //Create account
        Account portalAccount1 = new Account(	Name = 'TestAccount', ownerId = portalAccountOwner1.Id);
        Database.insert(portalAccount1);
        //Create contact
        Contact contact1 = new Contact(FirstName = 'Test',Lastname = 'McTesty',AccountId = portalAccount1.Id,Email = System.now().millisecond() + 'test@test.com');
        Database.insert(contact1);
        
        User portalAccountOwner2 = new User(UserRoleId = portalRole.Id,contactId=contact1.Id, ProfileId = profile2.Id,Username = System.now().millisecond() + 'test2@test.com',
                                            Alias = 'batman',	Email='bruce.wayne2@wayneenterprises.com',	EmailEncodingKey='UTF-8',	Firstname='Bruce',	Lastname='Wayne',
                                            LanguageLocaleKey='en_US',	LocaleSidKey='en_US',	TimeZoneSidKey='America/Chicago');
        
        System.runAs(new User(Id=UserInfo.getUserId())) {
        	Database.insert(portalAccountOwner2);
        }
        System.debug('portalAccountOwner1::'+portalAccountOwner1.Id);
        
        System.debug('portalAccount1::'+portalAccount1.Id);
        
        
        System.debug('contact1::'+contact1.Id);
        //Create user
        Profile portalProfile = [SELECT Id FROM Profile WHERE Name LIKE '%MCS Customer Community Plus User%' Limit 1];
        System.debug('portalProfile::'+portalProfile.Id);
        User user1 = new User(Username = System.now().millisecond() + 'test12345@test.com',ContactId = contact1.Id,	ProfileId = portalProfile.Id,
                              Alias = 'test123',	Email = 'test12345@test.com',	EmailEncodingKey = 'UTF-8',	LastName = 'McTesty',	CommunityNickname = 'test12345',
                              TimeZoneSidKey = 'America/Los_Angeles',	LocaleSidKey = 'en_US',	LanguageLocaleKey = 'en_US');
        Database.insert(user1);
        System.debug('user1::'+user1.Id);
        return user1;
    }
       
    public static User createUser(String ProfileName){        
        List<Profile> profile = [SELECT Id FROM Profile WHERE Name= :ProfileName];         
        if(profile.size() == 1){
            User u = new User(Alias = 'standt', Email='mcstest@testorg.com', 
                              EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                              LocaleSidKey='en_US', 
                              ProfileId = profile[0].id,
                              ManagerId = UserInfo.getUserId(),
                              TimeZoneSidKey='America/Los_Angeles', UserName='test'+Math.random()+'@testorg.com');        
            //Required to avoid MIXED_DML_OPERATION exception
            User thisUser = [ select Id from User where Id = :UserInfo.getUserId() ];
            System.runAs ( thisUser ) {
                insert u; 
            }            
            return u;
        }
        else{
            throw new QueryException('No profile found for profile name: ' + ProfileName);
        }  
    }
    
    public static Account createAccountRecords(String accName, String currencyCode,Boolean isInsert){
        Account account = new Account(Name=accName, CurrencyIsoCode =currencyCode);
        if(isInsert){insert account;}
        return account;
    }
    
    public static Contact createContactRecords(String fName, String lName, String accId, String currencyCode,Boolean isInsert){
        Contact contact = new Contact(FirstName=fName, LastName = lName,AccountId=accId, CurrencyIsoCode = currencyCode);
        if(isInsert){insert contact;}
        return contact;
    }
    
    public static Entitlement createEntitlementRecords(String entName, String accId, Date dt, String SlaId, String busHoursId,Boolean isInsert){
        Entitlement entitlement = new Entitlement(Name = entName,AccountId = accId,StartDate = dt,SlaProcessId = SlaId,BusinessHoursId = busHoursId);
        if(isInsert){insert entitlement;}
        return entitlement;
    }
    
    //-------------Create Standard Support Case---------------
    
    public static Case createStandardCaseRecords(String accId, String conId, String entId, String caseType, String priority, String status,Boolean isInsert){
        Case cases = new Case(AccountId = accId,RecordTypeId = CaseSelector.stdRecordType,ContactId = conId,EntitlementId = entId,Case_Types__c = caseType,Priority = priority,Status = status);
        if(isInsert){insert cases;}
        return cases;
    }
    
    //--------------Create Enhancement Case------------------
    public static Case createEnhanceCaseRecords(String accId, String conId, String entId, String priority, String status, Boolean isInsert){
        Case cases = new Case(AccountId = accId,RecordTypeId = enhanceCaseRecordTypeId, ContactId = conId, EntitlementId = entId, Case_Types__c = 'Enhancement',Priority = priority,Status = status, In_SLA__c = 'Yes');
        if(isInsert){insert cases;}
        return cases;
    }
    
    //-------------Create Hotfix Case----------------------
    public static Case createHotfixCaseRecords(String accId, String conId, String entId, String caseType, String priority, String status, Boolean isInsert){
        Case cases = new Case(AccountId = accId,RecordTypeId = hotfixCaseRecordTypeId,ContactId = conId,EntitlementId = entId,Case_Types__c = caseType,Priority = priority,Status = status);
        if(isInsert){insert cases;}
        return cases;
    }
    
    public static Case createHotfixCaseRecords1(String accId, String conId, String entId, String caseType,String priority, String status,String subStatus,String deliveryValues,String decisionValues,Boolean criticalSeverity,Boolean scriptApproval,Boolean isInsert){
        Case cases = new Case(AccountId = accId,RecordTypeId = hotfixCaseRecordTypeId,ContactId = conId,EntitlementId = entId,Case_Types__c=caseType,Priority=priority,Status=status,SubStatus__c =subStatus); 
        if(isInsert){insert cases;}	
        return cases;
    }
    
    public static Id getBusinessHours(String name){
        BusinessHours buHours = [SELECT Id FROM BusinessHours where Name =:name];
        return buHours.Id;
    }
    
    public static SlaProcess getSlaProcessNames(String processName){
        SlaProcess process = [SELECT Id,name FROM Slaprocess WHERE IsActive = true and name = : processName];
        return process;
    }
    
    public static User getGroupMemberId(String groupName){
        User users = [SELECT id FROM user WHERE id IN ( SELECT userOrGroupId FROM groupmember WHERE Group.Name = :groupName) limit 1];
        return users;
    }
    
}