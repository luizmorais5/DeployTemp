/*
 *
 *Name  :  CaseSelector
 *Author:  Thinqloud Solutions
 *Date  :  Jan 11, 2021
 *Purpose : This class contains the functions needed to support CaseDomain class.
 *
 */
public class CaseSelector {
  public static Map<String, Id> recordTypeMap = getRecordTypeNameVsIdMap();
  public static Id hotFixRecordType = recordTypeMap.get(
    Constants.HOTFIX_CASE_TYPE
  );
  public static Id enhcmtRecordType = recordTypeMap.get(
    Constants.ENHANCEMENT_RECORD_TYPE
  );
  public static Id stdRecordType = recordTypeMap.get(
    Constants.STD_PHOENIX_RECORD_TYPE
  );
  public static Id clientRecordtype = recordTypeMap.get(
    Constants.STD_CLIENT_PAGE_RECORD_TYPE
  );
  public static Id childCaseRecordType = recordTypeMap.get(
    Constants.CHILD_CASE_RECORD_TYPE
  );

  public static boolean l1counter = false;

  //---------------------------------------------------------------------------------------
  /**
   *	Method  :	getAvailableQueueGroup
   *	Author	:	Thinqloud Solutions
   *	Param	:
   *	Returns	:	Map<String, Group>
   *	Purpose :	This function return the map of Group object and key field is Froup name.
   **/
  public static Map<String, Group> getAvailableQueueGroup() {
    Map<String, Group> groupMap = new Map<String, Group>();
    for (Group grp : [
      SELECT Id, Name
      FROM Group
      WHERE Type = :Constants.QUEUE_TEXT
    ]) {
      groupMap.put(grp.Name, grp);
    }

    return groupMap;
  }

  /**
   *	Method  :	getGroupsMembersMap
   *	Author	:	Thinqloud Solutions
   *	Param	:
   *	Returns	:	Map<String, List<Id>>
   *	Purpose :	This function return the map of list of userids. Key field is Froup name.
   **/
  public static Map<String, List<Id>> getGroupsMembersMap() {
    List<GroupMember> groupList = [
      SELECT UserOrGroupId, Group.Name
      FROM GroupMember
    ];
    Map<String, List<Id>> groupMap = new Map<String, List<Id>>();
    for (GroupMember groups : groupList) {
      if (groupMap.containsKey(groups.Group.Name)) {
        List<Id> grpMemberList = groupMap.get(groups.Group.Name);
        grpMemberList.add(groups.UserOrGroupId);
        groupMap.put(groups.Group.Name, grpMemberList);
      } else {
        groupMap.put(groups.Group.Name, new List<Id>{ groups.UserOrGroupId });
      }
    }
    return groupMap;
  }

  /**
   *	Method  :	getRecordTypeNameVsIdMap
   *	Author	:	Thinqloud Solutions
   *	Param	:
   *	Returns	:	Map<String, Id>
   *	Purpose :	This function return the map of record type id. Key field is developer Name of RecordType record.
   **/
  public static Map<String, Id> getRecordTypeNameVsIdMap() {
    List<RecordType> recordTypeList = [
      SELECT Id, DeveloperName
      FROM RecordType
    ];
    Map<String, Id> recordtypeMap = new Map<String, Id>();
    for (RecordType rt : recordTypeList) {
      recordtypeMap.put(rt.DeveloperName, rt.Id);
    }
    return recordtypeMap;
  }
  /**
   * @description get all the record types for the given sobject name
   * @author Remario Richards | 09-03-2023
   * @param objectName
   * @return Map<String, Id>
   **/
  public static Map<String, Id> getRecordTypeNames(String objectName) {
    List<RecordType> recordTypeList = [
      SELECT Id, DeveloperName
      FROM RecordType
      WHERE SobjectType = :objectName
    ];
    Map<String, Id> recordtypeMap = new Map<String, Id>();
    for (RecordType rt : recordTypeList) {
      recordtypeMap.put(rt.DeveloperName, rt.Id);
    }
    return recordtypeMap;
  }

  /**
   * @description get all entitlements
   * @author Remario Richards | 09-03-2023
   * @return Map<String, Id>
   **/
  public static Map<String, Id> getEntitlements() {
    Map<String, Id> entMap = new Map<String, Id>();

    for (Entitlement record : [
      SELECT Id, Name
      FROM Entitlement
      WHERE Status = :Constants.ACTIVE
    ]) {
      entMap.put(record.Name.toLowerCase(), record.Id);
    }
    return entMap;
  }
  public static Map<Id, Account> getMerchantAccounts(Set<Id> ids) {
    return new Map<Id, Account>(
      [SELECT Id, Name, Parish__c FROM Account WHERE Id IN :ids]
    );
  }
  public static List<Merchant_Location__c> getMerchantLocationByIds(Set<Id> setId) {
    return [SELECT Id, Parish_Province_State_list__c, Country_list__c FROM Merchant_Location__c WHERE Id IN :setId];
  }   
  
  /**
   *	Method  :	getEntitlement
   *	Author	:	Thinqloud Solutions
   *	Param	:
   *	Returns	:	Map<ID, Map<String, Entitlement>>
   *	Purpose :	This function return the map of map of Entitlement record. Account Id is the key field of the map.
   **/
  // public static Map<ID, Map<String, Entitlement>> getEntitlement(
  //   Set<Id> accId
  // ) {
  //   List<Entitlement> entitlementList1 = [
  //     SELECT Id, Name, AccountId
  //     FROM Entitlement
  //     WHERE AccountId IN :accId AND Status = :Constants.ACTIVE
  //   ];
  //   Map<ID, Map<String, Entitlement>> accountVSEntitlementMap = new Map<ID, Map<String, Entitlement>>();
  //   for (Entitlement ent : entitlementList1) {
  //     if (accountVSEntitlementMap.containsKey(ent.AccountId)) {
  //       Map<String, Entitlement> entMap = accountVSEntitlementMap.get(
  //         ent.AccountId
  //       );
  //       entMap.put(ent.Name, ent);
  //       accountVSEntitlementMap.put(ent.AccountId, entMap);
  //     } else {
  //       Map<String, Entitlement> entMap = new Map<String, Entitlement>();
  //       entMap.put(ent.Name, ent);
  //       accountVSEntitlementMap.put(ent.AccountId, entMap);
  //     }
  //   }
  //   return accountVSEntitlementMap;
  // }

  /**
   *	Method  :	getemailTemplatesMap
   *	Author	:	Thinqloud Solutions
   *	Param	:
   *	Returns	:	Map<String, EmailTemplate>
   *	Purpose :	This function return the map of Email Templates. Developer Name of the email template is the key field of the map.
   **/
  public static Map<String, EmailTemplate> getemailTemplatesMap() {
    List<EmailTemplate> templateList = [
      SELECT Id, Body, Subject, Name, DeveloperName
      FROM EmailTemplate
    ];
    Map<String, EmailTemplate> emailTemplateMap = new Map<String, EmailTemplate>();
    for (EmailTemplate template : templateList) {
      emailTemplateMap.put(template.DeveloperName, template);
    }
    return emailTemplateMap;
  }

  /**
   *	Method  :	getQueueUsersInfo
   *	Author	:	Thinqloud Solutions
   *	Param	:
   *	Returns	:	Map<String, List<User>>
   *	Purpose :	This function return the map of List of users. Group Name is the key field of the map.
   **/
  public static Map<String, List<User>> getQueueUsersInfo() {
    List<GroupMember> groupList = [
      SELECT UserOrGroupId, Group.Name
      FROM GroupMember
    ];
    Map<Id, User> usersMap = new Map<Id, User>(
      [SELECT Id, Name, Email FROM User WHERE isActive = TRUE]
    );

    Map<String, List<User>> grpNameVsUsersListMap = new Map<String, List<User>>();
    for (GroupMember grpMember : groupList) {
      if (grpNameVsUsersListMap.containsKey(grpMember.Group.Name)) {
        List<User> userList = grpNameVsUsersListMap.get(grpMember.Group.Name);
        userList.add(usersMap.get(grpMember.UserOrGroupId));
        grpNameVsUsersListMap.put(grpMember.Group.Name, userList);
      } else {
        grpNameVsUsersListMap.put(
          grpMember.Group.Name,
          new List<user>{ usersMap.get(grpMember.UserOrGroupId) }
        );
      }
    }
    return grpNameVsUsersListMap;
  }

  /**
   *	Method  :	completeMilestone
   *	Author	:	Thinqloud Solutions
   *	Param	:	List<Id> caseIds
   *			:	list<String> milestoneName
   *			:	DateTime completionDate
   *	Returns	:	Void
   *	Purpose :	This function mark the milestone to complete status by assigning date to the completion date of milestone.
   **/
  public static void completeMilestone(
    List<Id> caseIds,
    list<String> milestoneName,
    DateTime completionDate
  ) {
    if (caseIds.size() > 0 && milestoneName.size() > 0) {
      List<CaseMilestone> cmsToUpdate = [
        SELECT Id, completionDate
        FROM CaseMilestone cm
        WHERE
          caseId IN :caseIds
          AND cm.MilestoneType.Name IN :milestoneName
          AND completionDate = NULL
      ];
      if (cmsToUpdate.isEmpty() == false) {
        for (CaseMilestone cm : cmsToUpdate) {
          cm.completionDate = completionDate;
        }
        update cmsToUpdate;
      }
    }
  }

  /**
   *	Method  :	matchOwner
   *	Author	:	Thinqloud Solutions
   *	Param	:	Id ownerId
   *			:	String queueName
   *			:	DateTime completionDate
   *			:	Map<String, Group> groupMap
   *			:	Map<String, List<Id>> groupMemMap
   *	Returns	:	Boolean
   *	Purpose :	This function checks if the owner Id in the parameter belong to the Id of the given queue name.
   *				Or it checks if the Owner Id belongs to the any user of the Queue.
   *				If it does belong then returns True else False.
   **/
  // public static Boolean matchOwner(
  //   Id ownerId,
  //   String queueName,
  //   Map<String, Group> groupMap,
  //   Map<String, List<Id>> groupMemMap
  // ) {
  //   if (
  //     groupMap.get(queueName).Id == ownerId ||
  //     groupMemMap.get(queueName).contains(ownerId)
  //   ) {
  //     return true;
  //   }
  //   return false;
  // }

  /**
   *	Method  :	sendEmailToUsers
   *	Author	:	Thinqloud Solutions
   *	Param	:	Case cs
   *			:	EmailTemplate template
   *			:	List<User> userList
   *			:	boolean sendEmailToClient
   *	Returns	:	Messaging.SingleEmailMessage
   *	Purpose :	This function prepars the list of mails to be sent.
   **/
  // public static Messaging.SingleEmailMessage sendEmailToUsers(
  //   Case cs,
  //   EmailTemplate template,
  //   List<User> userList,
  //   boolean sendEmailToClient
  // ) {
  //   List<String> toMail = new List<String>();
  //   if (!userList.isEmpty()) {
  //     for (User userObj : userList) {
  //       if (userObj.email != null) {
  //         toMail.add(userObj.email);
  //       }
  //     }
  //   }
  //   Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

  //   mail.setToAddresses(toMail);
  //   mail.setTargetObjectId(cs.ContactId);
  //   mail.setTreatTargetObjectAsRecipient(sendEmailToClient);
  //   mail.setTemplateId(template.id);
  //   mail.setSaveAsActivity(true);
  //   mail.setWhatId(cs.Id);
  //   return mail;
  // }

  /**
   *	Method  :	getAccountMap
   *	Author	:	Thinqloud Solutions
   *	Param	:	Set<Id> accountIdsSet
   *	Returns	:	map<Id, Account>
   *	Purpose :	This function returns the map of account object. Key is account Id.
   **/
  // public static map<Id, Account> getAccountMap(Set<Id> accountIdsSet) {
  //   map<Id, Account> accountMap;
  //   if (accountIdsSet != null && accountIdsSet.size() > 0) {
  //     accountMap = new Map<Id, Account>(
  //       [
  //         SELECT id, FirstName, LastName, Name
  //         FROM Account
  //         WHERE id IN :accountIdsSet
  //       ]
  //     );
  //   }
  //   return accountMap;
  // }

  /**
   *	Method  :	getContactMap
   *	Author	:	Thinqloud Solutions
   *	Param	:	Set<Id> contactIdsSet
   *	Returns	:	map<Id, Contact>
   *	Purpose :	This function returns the map of Contact object. Key is Contact Id.
   **/
  // public static map<Id, Contact> getContactMap(Set<Id> contactIdsSet) {
  //   map<Id, Contact> contactMap;
  //   if (contactIdsSet != null && contactIdsSet.size() > 0) {
  //     contactMap = new Map<Id, Contact>(
  //       [SELECT id, FirstName, LastName FROM Contact WHERE id IN :contactIdsSet]
  //     );
  //   }
  //   return contactMap;
  // }

  /**
   *	Method  :	getUserDetail
   *	Author	:	Thinqloud Solutions
   *	Param	:	Id userId
   *	Returns	:	User
   *	Purpose :	This function returns the Record of User object.
   **/
  public static User getUserDetail(Id userId) {
    User userDetail;
    if (userId != null) {
      userDetail = [SELECT Name, Email FROM User WHERE id = :userId];
    }
    return userDetail;
  }
  /**
   * @description retrieve a list of service appointments for given work orders
   * @author Remario Richards | 09-17-2023
   * @param workOrders
   * @return List<ServiceAppointment>
   **/
  public static List<ServiceAppointment> getServiceAppointments(
    Set<Id> workOrders
  ) {
    return [
      SELECT Id, SchedStartTime, FSSK__FSK_Work_Order__c
      FROM ServiceAppointment
      WHERE FSSK__FSK_Work_Order__c IN :workOrders
    ];
  }
  /**
   * Retrieves a list of active CaseMilestones based on specified criteria.
   *
   * This method queries the CaseMilestone object to find active milestones associated
   * with the provided Case Ids and matching milestone names.
   *
   * @param milestoneNames Set<String> - A list of milestone names to query for.
   * @param caseIds Set<Id> - A set of Case Ids to filter the query by.
   *
   * @return List<CaseMilestone> - A list of active CaseMilestone records that meet the criteria.
   */
  public static List<CaseMilestone> getActiveMilestonesForCases(
    Set<String> milestoneNames,
    Set<Id> caseIds
  ) {
    // Define your SOQL query
    String milestoneQuery = 'SELECT Id, MilestoneType.Name, IsCompleted FROM CaseMilestone WHERE CaseId IN :caseIds AND MilestoneType.Name IN :milestoneNames AND IsCompleted = false';

    // Execute the query using Database.query() method
    List<CaseMilestone> activeMilestones = Database.query(milestoneQuery);

    return activeMilestones;
  }
}