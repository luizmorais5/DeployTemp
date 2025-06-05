/**
 * @description       :
 * @author            : Remario Richards
 * @group             :
 * @last modified on  : 01-02-2024
 * @last modified by  : Remario Richards
 **/
public with sharing class AssetWrapper {
  @AuraEnabled
  public String accountName { get; set; }
  @AuraEnabled
  public String id { get; set; }
  @AuraEnabled
  public String name { get; set; }
  @AuraEnabled
  public String terminalId { get; set; }
  @AuraEnabled
  public String terminalIdName { get; set; }
  @AuraEnabled
  public String serialNumber { get; set; }
  @AuraEnabled
  public String productName { get; set; }
  @AuraEnabled
  public String productId { get; set; }
  @AuraEnabled
  public String assetProvidedByAccount { get; set; }
  @AuraEnabled
  public String assetProvidedByAccountId { get; set; }
  @AuraEnabled
  public String simCard1 { get; set; }
  @AuraEnabled
  public String simCard2 { get; set; }
  @AuraEnabled
  public String simCard1Name { get; set; }
  @AuraEnabled
  public String simCard2Name { get; set; }
  @AuraEnabled
  public String typeValueSelected { get; set; }

  /**
   * @description primary constructor
   * @author Remario Richards | 11-04-2023
   * @param record
   **/
  public AssetWrapper(Asset record) {
    this.accountName = record.Account.Name;
    this.id = record.Id;
    this.name = record.Name;
    this.terminalId = record.Terminal_id__c;
    this.serialNumber = record.SerialNumber;
    this.productId = record.Product2Id;
    this.productName = record.Product2.Name;
    this.assetProvidedByAccount = record.AssetProvidedBy.Name;
    this.assetProvidedByAccountId = record.AssetProvidedById;
    this.terminalIdName = record.Terminal_id__r.Name;
    this.simCard1 = record.Sim_Card_1__c;
    this.simCard2 = record.Sim_Card_2__c;
    this.simCard1Name = record?.Sim_Card_1__r?.SerialNumber;
    this.simCard2Name = record?.Sim_Card_2__r?.SerialNumber;
  }
  /**
   * @description primary constructor
   * @author Remario Richards | 11-04-2023
   * @param record
   **/
  public AssetWrapper(ReturnOrderLineItem record) {
    this.accountName = record.Asset.Account.Name;
    this.id = record.Asset.Id;
    this.name = record.Asset.Name;
    this.terminalId = record.Asset.Terminal_id__c;
    this.serialNumber = record.Asset.SerialNumber;
    this.productId = record.Asset.Product2Id;
    this.productName = record.Asset.Product2.Name;
    this.assetProvidedByAccount = record.Asset.AssetProvidedBy.Name;
    this.assetProvidedByAccountId = record.Asset.AssetProvidedById;
    this.terminalIdName = record.Asset.Terminal_id__r.Name;
    this.simCard1 = record.Asset.Sim_Card_1__c;
    this.simCard2 = record.Asset.Sim_Card_2__c;
    this.simCard1Name = record.Asset?.Sim_Card_1__r?.SerialNumber;
    this.simCard2Name = record.Asset?.Sim_Card_2__r?.SerialNumber;
  }
}