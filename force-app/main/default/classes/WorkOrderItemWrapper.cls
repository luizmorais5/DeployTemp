/**
 * @description       : 
 * @author            : Remario Richards
 * @group             : 
 * @last modified on  : 11-21-2023
 * @last modified by  : Remario Richards
**/
public with sharing class WorkOrderItemWrapper {
  @AuraEnabled
  public List<AssetWrapper> assets = new List<AssetWrapper>();
  @AuraEnabled
  public String workOrderId { get; set; }
  @AuraEnabled
  public String id { get; set; }
  @AuraEnabled
  public String assetId { get; set; }
  @AuraEnabled
  public String status { get; set; }

  /**
  * @description main constructor
  * @author Remario Richards | 11-21-2023 
  * @param record 
  **/
  public WorkOrderItemWrapper(WorkOrderLineItem record){
    this.id = record.Id;
    this.workOrderId = record.WorkOrderId;
    this.assetId = record.AssetId;
    this.status = record.Status;
    this.assets.add(new AssetWrapper(record));
  }
}