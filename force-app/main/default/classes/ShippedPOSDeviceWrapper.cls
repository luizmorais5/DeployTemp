public class ShippedPOSDeviceWrapper {
    @AuraEnabled public String id { get; set; }
    @AuraEnabled public String serialNumber { get; set; }
    @AuraEnabled public String model { get; set; }
    @AuraEnabled public String tid { get; set; }
    @AuraEnabled public String simCard1 { get; set; }
    @AuraEnabled public String simCard2 { get; set; }
    @AuraEnabled public String caseId { get; set; }
    @AuraEnabled public String caseNumber { get; set; }
    @AuraEnabled public String merchantName { get; set; }
    @AuraEnabled public String merchantAddress { get; set; }
    @AuraEnabled public String bankName { get; set; }
    @AuraEnabled public Boolean shipped { get; set; }
    @AuraEnabled public Boolean received { get; set; }
    @AuraEnabled public Boolean reship { get; set; }
    @AuraEnabled public String reshipDestination { get; set; }
    @AuraEnabled public String assignedTerritoryHub { get; set; }
    @AuraEnabled public DateTime dateSent { get; set; }
    @AuraEnabled public String dateShipped { get; set; }
    @AuraEnabled public DateTime dateReceived { get; set; }
    @AuraEnabled public String serviceTerritory { get; set; }
    @AuraEnabled public String destinationType { get; set; }
    
    public ShippedPOSDeviceWrapper(SerializedProduct serializedProduct, Terminal_ID__c terminal, Case caseRecord) {
        this.id = serializedProduct.Id;
        this.serialNumber = serializedProduct.SerialNumber;
        this.model = serializedProduct.Product2?.Name;
        
        if (terminal != null) {
            this.tid = terminal.Name;
            this.simCard1 = terminal.SIM_Card_Id__c;
            this.simCard2 = terminal.SIM_Card_2_Id__c;
            
            if (String.isNotBlank(terminal.Service_Territory_text__c)) {
                this.serviceTerritory = terminal.Service_Territory_text__c;
            }
        }
        
        if (caseRecord != null) {
            this.caseId = caseRecord.Id;
            this.caseNumber = caseRecord.CaseNumber;
            this.merchantName = caseRecord.Account.Name;
            this.assignedTerritoryHub = caseRecord.Service_Territory__c;
            
            if (String.isBlank(this.serviceTerritory) && String.isNotBlank(caseRecord.Service_Territory__c)) {
                this.serviceTerritory = caseRecord.Service_Territory__c;
            }
            
            if (caseRecord.Merchant_Location_Id__r != null) {
                String address1 = String.isNotBlank(caseRecord.Merchant_Location_Id__r.Address_1_text__c) ? 
                    caseRecord.Merchant_Location_Id__r.Address_1_text__c : '';
                String address2 = String.isNotBlank(caseRecord.Merchant_Location_Id__r.Address_2_text__c) ? 
                    caseRecord.Merchant_Location_Id__r.Address_2_text__c : '';
                String address3 = String.isNotBlank(caseRecord.Merchant_Location_Id__r.Address_3_text__c) ? 
                    caseRecord.Merchant_Location_Id__r.Address_3_text__c : '';
                String parish = String.isNotBlank(caseRecord.Merchant_Location_Id__r.Parish_Province_State_list__c) ? 
                    caseRecord.Merchant_Location_Id__r.Parish_Province_State_list__c : '';
                String country = String.isNotBlank(caseRecord.Merchant_Location_Id__r.Country_list__c) ? 
                    caseRecord.Merchant_Location_Id__r.Country_list__c : '';
                
                this.merchantAddress = String.join(new List<String>{address1, address2, address3, parish, country}, ', ')
                    .removeEnd(', ').replaceAll(' ,', '');
            }
        }
        
        if (serializedProduct.Bank_Id__r != null) {
            this.bankName = serializedProduct.Bank_Id__r.Name;
        }

        this.shipped = false;
        this.received = false;
        this.reship = false;
        this.reshipDestination = '';
        this.destinationType = '';
    }
    
    public String getFormattedDateSent() {
        if (this.dateSent != null) {
            return this.dateSent.format('MMM dd, yyyy HH:mm');
        }
        return '';
    }
    
    public String getFormattedDateReceived() {
        if (this.dateReceived != null) {
            return this.dateReceived.format('MMM dd, yyyy HH:mm');
        }
        return '';
    }
}