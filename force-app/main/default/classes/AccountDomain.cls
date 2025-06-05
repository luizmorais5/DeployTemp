public class AccountDomain {
    
    public static void createEntitlements(List<Account> accList){
        List<Entitlement> entitlementRecordList = new List<Entitlement>();
        List<SLAProcess> entitlementList = [SELECT Id
                                                 , Description
                                                 , Name
                                                 , IsActive
                                                 , IsVersionDefault 
                                              FROM SlaProcess 
                                             WHERE (Name LIKE 'Medium%' OR Name LIKE 'High%' OR Name LIKE 'Low%' OR Name LIKE 'Critical%') 
                                               AND IsActive = true 
                                               AND IsVersionDefault = true];
        for(Account acc: accList){
            for(SLAProcess sla:entitlementList){
                Entitlement entitlementRecord = new Entitlement();
                entitlementRecord.AccountId = acc.Id;
                entitlementRecord.SlaProcessId = sla.Id;
                entitlementRecord.Name = sla.Name;
                entitlementRecord.StartDate = System.today();
                entitlementRecord.EndDate = System.today().addYears(1);
                entitlementRecordList.add(entitlementRecord);
            }
        }
        
        if(entitlementRecordList.size() > 0){
            insert entitlementRecordList;
        }
    }

}