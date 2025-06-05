/**
 * @description       : 
 * @author            : Remario Richards
 * @group             : 
 * @last modified on  : 11-28-2023
 * @last modified by  : Remario Richards
**/
public with sharing class ReturnOrderLineItemWrapper {
  @AuraEnabled
  public AssetWrapper asset  { get; set; }
  @AuraEnabled
  public String workOrderId { get; set; }
  @AuraEnabled
  public String id { get; set; }
  @AuraEnabled
  public String status { get; set; }
  @AuraEnabled
  public String simCard1Status { get; set; }
  @AuraEnabled
  public String simCard2Status { get; set; }
  @AuraEnabled
  public String simCard1Value { get; set; }
  @AuraEnabled
  public String simCard2Value { get; set; }
  @AuraEnabled
  public String sim1NameCalc { get; set; }
  @AuraEnabled
  public String sim2NameCalc { get; set; }
  /**
  * @description main constructor
  * @author Remario Richards | 11-21-2023 
  * @param record 
  **/
  public ReturnOrderLineItemWrapper(ReturnOrderLineItem record){
    this.id = record.Id;
    this.workOrderId = record.Work_Order_Id__c;
    this.status = record.Status_list__c;
    this.simCard1Status = this.val(record?.SIM_Card_1_Status_list__c);
    this.simCard2Status = this.val(record?.SIM_Card_2_Status_list__c);
    this.simCard1Value = this.val(record?.SIM_Card_1_text__c);
    this.simCard2Value = this.val(record?.SIM_Card_2_text__c);
    this.sim1NameCalc = this.val(record?.SIM_Card_1_calc__c);
    this.sim2NameCalc = this.val(record?.SIM_Card_2_calc__c);
    this.asset = new AssetWrapper(record);
  }
  private string val(String value) {
    if (String.isBlank(value)){
      return '';
    }
    return value;
  }
}