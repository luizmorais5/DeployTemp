/**
* @description       : Wrapper class for Entitlement Settings
* @author            : Remario Richards
* @last modified on  : 12-20-2023
* @last modified by  : Remario Richards
**/
public with sharing class EntitlementSettingWrapper {
  public Map<String, List<Record>> mappedSettings = new Map<String, List<Record>>();
  private static Map<String, BusinessHours> businessHoursCache = new Map<String, BusinessHours>();
  /**
   * @description primary constructor
   * @author Remario Richards | 12-02-2023
   **/
  public EntitlementSettingWrapper() {
      List<Entitlement_Setting__mdt> allSettings = getAllSettings();
      Set<String> businessHourNames = new Set<String>();
      for (Entitlement_Setting__mdt setting : allSettings) {
          businessHourNames.add(setting.Business_Hour_for_Bank__c);
      }
      Map<String, BusinessHours> businessHoursMap = getBusinessHoursMap(businessHourNames);
      for (Entitlement_Setting__mdt setting : allSettings) {
          Record recordSetting = new Record(setting, businessHoursMap.get(setting.Business_Hour_for_Bank__c));
          if (!mappedSettings.containsKey(recordSetting.bank)) {
              mappedSettings.put(recordSetting.bank, new List<Record>());
          }
          mappedSettings.get(recordSetting.bank).add(recordSetting);
      }
  }
  /**
   * @description get all settings
   * @author Remario Richards | 12-02-2023
   * @return List<Entitlement_Setting__mdt>
   **/
  public static List<Entitlement_Setting__mdt> getAllSettings() {
      return Entitlement_Setting__mdt.getAll().values();
  }
  /**
   * @description get map of BusinessHours by name
   * @author Remario Richards | 12-20-2023
   * @param businessHourNames Set of BusinessHours names
   * @return Map<String, BusinessHours>
   **/
  private static Map<String, BusinessHours> getBusinessHoursMap(Set<String> businessHourNames) {
      Map<String, BusinessHours> result = new Map<String, BusinessHours>();
      for (BusinessHours bh : [SELECT Id, Name FROM BusinessHours WHERE Name IN :businessHourNames WITH SYSTEM_MODE]) {
          result.put(bh.Name, bh);
      }
      return result;
  }
  /**
   * @description get BusinessHours record for bank
   * @author Remario Richards | 12-02-2023
   * @param businessHoursName
   * @return BusinessHours
   **/
  public static BusinessHours getBusinessHourRecordForBank(String businessHoursName) {
      if (!businessHoursCache.containsKey(businessHoursName)) {
          List<BusinessHours> records = [SELECT Id FROM BusinessHours WHERE Name = :businessHoursName WITH SYSTEM_MODE LIMIT 1];
          if (records.isEmpty()) {
              throw new StringException('No configured business hours for : ' + businessHoursName);
          }
          businessHoursCache.put(businessHoursName, records[0]);
      }
      return businessHoursCache.get(businessHoursName);
  }
  /**
   * @description get bank business hours configuration
   * @author Remario Richards | 12-04-2023
   * @param bank
   * @return BusinessHours
   **/
  public static BusinessHours searchBusinessHourRecordForBank(String bank) {
      List<Entitlement_Setting__mdt> records = [
          SELECT Id, Business_Hour_for_Bank__c
          FROM Entitlement_Setting__mdt
          WHERE Bank__c = :bank
          WITH SYSTEM_MODE
          LIMIT 1
      ];
      
      if (records.isEmpty()) {
        return getBusinessHourRecordForBank(bank);
      }
      if (!records.isEmpty()) {
          return getBusinessHourRecordForBank(records[0].Business_Hour_for_Bank__c);
      }
      return null;
  }
  public class Record {
      public String serviceTypes;
      public String slaType;
      public String radiusDistance;
      public String radiusDistanceType;
      public String parishes;
      public String country;
      public String recordTypeName;
      public String bank;
      public String bankBusinessName;
      public String entitlementName;
      public BusinessHours bankBusinessHours;
      public Boolean applyDistanceCheck;
      /**
       * @description primary constructor
       * @author Remario Richards | 12-02-2023
       * @param setting
       * @param businessHours
       **/
      public Record(Entitlement_Setting__mdt setting, BusinessHours businessHours) {
          this.bank = setting.Bank__c;
          this.bankBusinessName = setting.Business_Hour_for_Bank__c;
          this.recordTypeName = setting.Case_RecordType_Name__c;
          this.entitlementName = setting.Entitlement_Name__c;
          this.radiusDistance = setting.Kilometer_Radius__c;
          this.radiusDistanceType = setting.Kilometer_Radius_Type__c;
          this.parishes = setting.Parishes__c;
          this.country = setting.Country__c;
          this.serviceTypes = setting.Service_Types__c;
          this.slaType = setting.SLA_Type__c;
          this.bankBusinessHours = businessHours;
          this.applyDistanceCheck = setting.use_distance_check__c;
      }
  }
}