public with sharing class GoogleApiKeyProvider implements IGoogleApiKeyProvider {
    public String getApiKey() {
        ApiConfig__mdt config = [
            SELECT ApiKey__c FROM ApiConfig__mdt WHERE MasterLabel = 'GoogleApiConfig' LIMIT 1
        ];
        return config.ApiKey__c;
    }
}