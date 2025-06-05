/**
 *Name  :  CaseTriggerHandler
 *Author:  Thinqloud Solutions
 *Date  :  Jan 11, 2021
 *Purpose : Case Trigger Handler
 **/
public class CaseTriggerHandler implements ITriggerHandler {
  public Map<Id, Account> merchantAccounts;
  /**
   *	Method  :	beforeInsert
   *	Author	:	Thinqloud Solutions
   *	Param	:	List<SObject> newItems
   *	Returns	:	void
   *	Purpose :	This function is the called when before insert event of case occure.
   **/
  public void beforeInsert(List<SObject> newItems) {
    List<Case> newCaseList = (List<Case>) newItems;
    List<Case> enhancementList = new List<Case>();
    List<Case> standardList = new List<Case>();
    List<Case> hotfixList = new List<Case>();
    List<Case> clientList = new List<Case>();

    Set<ID> enhancAccountIdSet = new Set<Id>();
    Set<ID> stdAccountIdSet = new Set<Id>();
    Set<ID> hotAccountIdSet = new Set<Id>();
    Set<Id> merchantAccountIds = new Set<Id>();
    Set<Id> merchantLocationIds = new Set<Id>();  

    for (Case caseObj : newCaseList) {
      merchantAccountIds.add(caseObj.AccountId);
      merchantAccountIds.add(caseObj.Merchant_Name_ID__c);
      merchantLocationIds.add(caseObj.Merchant_Location_Id__c);  
    }
    this.merchantAccounts = CaseSelector.getMerchantAccounts(merchantAccountIds);
	Map<Id, Merchant_Location__c> merchantLocationMap = new Map<Id, Merchant_Location__c>(CaseSelector.getMerchantLocationByIds(merchantLocationIds));
    Map<String, Id> mappedEntitlements = CaseSelector.getEntitlements();
    CaseDomain.assignAllEntitlementsV2(
      newCaseList,
      this.merchantAccounts,
      mappedEntitlements,
      merchantLocationMap
    );
      
   ATMCaseSLAManager.processATMSlaCases(newCaseList, null);
  }

  /**
   *	Method  :	beforeUpdate
   *	Author	:	Thinqloud Solutions
   *	Param	:	List<SObject> newItems
   *			:	Map<Id, SObject> oldItems
   *	Returns	:	void
   *	Purpose :	This function is the called when before update event of case occure.
   **/
  public void beforeUpdate(List<SObject> newItems, Map<Id, SObject> oldItems) {
    Set<ID> stdAccountIdSet = new Set<Id>();
    Set<ID> stdContactIdSet = new Set<Id>();
    Map<Id, case> oldMap = (Map<Id, case>) oldItems;
    List<Case> newCaseList = (List<Case>) newItems;
    List<Case> enhancementList = new List<Case>();
    List<Case> standardList = new List<Case>();
    List<Case> hotfixList = new List<Case>();
    List<Case> caseListToAssignEntitlement = new List<Case>();
    List<Case> childCaseList = new List<Case>();
    List<Case> stoppedCases = new List<Case>();
    List<Case> unStoppedCases = new List<Case>();
    Set<Id> AccountIdsSet = new Set<Id>();
    Set<Id> ContactIdsSet = new Set<Id>();
    Set<ID> accountIdSetForEntitlement = new Set<Id>();
    map<Id, Account> accountMap;
    map<Id, Contact> contactMap;
    Set<Id> merchantAccountIds = new Set<Id>();
    for (Case caseObj : newCaseList) {
      if (oldMap.get(caseObj.Id).isStopped && !caseObj.isStopped) {
        //case was just stopped
        unStoppedCases.add(caseObj);
      }
      merchantAccountIds.add(caseObj.AccountId);
      merchantAccountIds.add(caseObj.Merchant_Name_ID__c);
    } //----For Loop Ends here----------------
    this.merchantAccounts = CaseSelector.getMerchantAccounts(
      merchantAccountIds
    );
    CaseDomain.processUnStoppedCases(
      unStoppedCases,
      (Map<id, Case>) oldItems,
      this.merchantAccounts
    );
    CaseDomain.processAutomaticSLAPauseScenarios((List<Case>) newItems);
    List<Case> stoppedCases2 = CaseDomain.automaticUnpausingOfSLA(
      newItems,
      (Map<id, Case>) oldItems
    );
    CaseDomain.processUnStoppedCases(
      stoppedCases2,
      (Map<id, Case>) oldItems,
      this.merchantAccounts
    ); //for newly stopped cases
      
    ATMCaseSLAManager.processATMSlaCases(newCaseList, (Map<id, Case>) oldItems);

  }
  /**
   *	Method  :	afterInsert
   *	Author	:	Thinqloud Solutions
   *	Param	:	List<SObject> newItems
   *	Returns	:	void
   *	Purpose :	This function is the called when after insert event of case occure.
   **/
  public void afterInsert(List<SObject> newItems) {
    List<Case> newCaseList = (List<Case>) newItems;
    List<Case> standardList = new List<Case>();
    Set<ID> accountIdSet = new Set<Id>();

    CaseDomain.populateCommunityLink(newCaseList);  

    ATMCaseSLAManager.calculateKilometerRadius(newCaseList, null);
    ATMCaseSLAManager.populateATMHubLocation(newCaseList);
  }

  public void afterUpdate(List<SObject> newItems, Map<Id, SObject> oldItems) {
    List<Case> newCaseList = (List<Case>) newItems;

   // CaseDomain.scheduleAutoCaseUpdates(
      //(List<Case>) newItems,
      //(Map<Id, Case>) oldItems
    //);
    CaseDomain.regularAndPremiumMilestoneCompletionCriteria(
      (List<Case>) newItems,
      (Map<id, Case>) oldItems
    );

    CaseDomain.populateCommunityLink(newCaseList);
    
    ATMCaseSLAManager.calculateKilometerRadius(newCaseList, (Map<id, Case>) oldItems);
    ATMCaseSLAManager.populateATMHubLocation(newCaseList);

    CaseSLAManager.deleteScheduledJobs(
      (List<Case>) newItems,
      (Map<id, Case>) oldItems
    );

  }

  public void afterDelete(Map<Id, SObject> oldItems) {
  }

  public void afterUndelete(Map<Id, SObject> oldItems) {
  }

  public void beforeDelete(Map<Id, SObject> oldItems) {
  }
}