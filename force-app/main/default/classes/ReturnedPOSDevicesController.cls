public with sharing class ReturnedPOSDevicesController {

    @AuraEnabled
    public static List<ReturnedPOSDeviceWrapper> getReturnedPOSDevices() {
        try {
            Set<String> currentUserTerritories = getCurrentUserTerritories();
            List<ReturnedPOSDeviceWrapper> devices = new List<ReturnedPOSDeviceWrapper>();

            // Query SerializedProducts that have been flagged as returned via ProductTransfer
            // Scenarios 2-5: Devices from completed SAs with different statuses
            List<SerializedProduct> returnedProducts;

            if (currentUserTerritories.isEmpty()) {
                // No territory restrictions - show all returned devices
                returnedProducts = [
                    SELECT Id, SerialNumber, Product2.Name, Product2Id, Terminal_ID_TID_Id__c, Bank_Id__r.Name
                    FROM SerializedProduct
                    WHERE Id IN (
                        SELECT SerializedProductId
                        FROM ProductTransferState
                        WHERE ProductTransfer.Status = 'Returned'
                        AND ProductTransfer.IsReceived = false
                    )
                ];
            } else {
                // Filter by user territories
                returnedProducts = [
                    SELECT Id, SerialNumber, Product2.Name, Product2Id, Terminal_ID_TID_Id__c, Bank_Id__r.Name
                    FROM SerializedProduct
                    WHERE Id IN (
                        SELECT SerializedProductId
                        FROM ProductTransferState
                        WHERE ProductTransfer.Status = 'Returned'
                        AND ProductTransfer.IsReceived = false
                    )
                    AND Terminal_ID_TID_Id__r.Service_Territory_text__c IN :currentUserTerritories
                ];
            }

            Set<Id> terminalIds = new Set<Id>();
            for (SerializedProduct serializedProduct : returnedProducts) {
                if (serializedProduct.Terminal_ID_TID_Id__c != null) {
                    terminalIds.add(serializedProduct.Terminal_ID_TID_Id__c);
                }
            }

            Map<Id, Terminal_ID__c> terminalMap = new Map<Id, Terminal_ID__c>([
                SELECT Id, Name, SIM_Card_Id__c, SIM_Card_2_Id__c, Case__c
                FROM Terminal_ID__c
                WHERE Id IN :terminalIds
            ]);

            Set<Id> serviceAssignmentIds = new Set<Id>();
            for (Terminal_ID__c terminal : terminalMap.values()) {
                if (terminal.Case__c != null) {
                    serviceAssignmentIds.add(terminal.Case__c);
                }
            }

            Map<Id, Case> caseMap = new Map<Id, Case>([
                SELECT Id, Account.Name, CaseNumber, Service_Territory__c,
                       Merchant_Location_Id__r.Address_1_text__c,
                       Merchant_Location_Id__r.Address_2_text__c,
                       Merchant_Location_Id__r.Address_3_text__c,
                       Merchant_Location_Id__r.Parish_Province_State_list__c,
                       Merchant_Location_Id__r.Country_list__c
                FROM Case
                WHERE Id IN :serviceAssignmentIds
            ]);

            for (SerializedProduct serializedProduct : returnedProducts) {
                Terminal_ID__c terminal = terminalMap.get(serializedProduct.Terminal_ID_TID_Id__c);
                Case caseRecord = null;
                if (terminal != null && terminal.Case__c != null) {
                    caseRecord = caseMap.get(terminal.Case__c);
                }

                ReturnedPOSDeviceWrapper returnedDeviceWrapper = new ReturnedPOSDeviceWrapper(serializedProduct, terminal, caseRecord);
                returnedDeviceWrapper.accepted = false;
                devices.add(returnedDeviceWrapper);
            }

            return devices;

        } catch (Exception e) {
            throw new ReturnedPOSDevicesControllerException('Error retrieving returned POS devices: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static List<ReturnedPOSDeviceWrapper> getAcceptedReturnedPOSDevices() {
        try {
            Set<String> currentUserTerritories = getCurrentUserTerritories();
            List<ReturnedPOSDeviceWrapper> devices = new List<ReturnedPOSDeviceWrapper>();

            // Query SerializedProducts that have been accepted and moved to programming locations
            // Scenario 8: Accepted returned devices now in bank programming locations
            List<SerializedProduct> acceptedProducts;

            if (currentUserTerritories.isEmpty()) {
                // No territory restrictions - show all accepted devices
                acceptedProducts = [
                    SELECT Id, SerialNumber, Product2.Name, Product2Id, Terminal_ID_TID_Id__c, Bank_Id__r.Name
                    FROM SerializedProduct
                    WHERE Id IN (
                        SELECT SerializedProductId
                        FROM ProductTransferState
                        WHERE ProductTransfer.Status = 'Received'
                    )
                ];
            } else {
                // Filter by user territories - include unprogrammed accepted devices (Terminal_ID_TID_Id__c = null)
                // OR devices that match territory filter
                acceptedProducts = [
                    SELECT Id, SerialNumber, Product2.Name, Product2Id, Terminal_ID_TID_Id__c, Bank_Id__r.Name
                    FROM SerializedProduct
                    WHERE Id IN (
                        SELECT SerializedProductId
                        FROM ProductTransferState
                        WHERE ProductTransfer.Status = 'Received'
                    )
                    AND (Terminal_ID_TID_Id__c = null 
                         OR (Terminal_ID_TID_Id__c != null 
                             AND Terminal_ID_TID_Id__r.Service_Territory_text__c IN :currentUserTerritories))
                ];
            }

            Set<Id> terminalIds = new Set<Id>();
            for (SerializedProduct serializedProduct : acceptedProducts) {
                if (serializedProduct.Terminal_ID_TID_Id__c != null) {
                    terminalIds.add(serializedProduct.Terminal_ID_TID_Id__c);
                }
            }

            Map<Id, Terminal_ID__c> terminalMap = new Map<Id, Terminal_ID__c>([
                SELECT Id, Name, SIM_Card_Id__c, SIM_Card_2_Id__c, Case__c
                FROM Terminal_ID__c
                WHERE Id IN :terminalIds
            ]);

            Set<Id> serviceAssignmentIds = new Set<Id>();
            for (Terminal_ID__c terminal : terminalMap.values()) {
                if (terminal.Case__c != null) {
                    serviceAssignmentIds.add(terminal.Case__c);
                }
            }

            Map<Id, Case> caseMap = new Map<Id, Case>([
                SELECT Id, Account.Name, CaseNumber, Service_Territory__c,
                       Merchant_Location_Id__r.Address_1_text__c,
                       Merchant_Location_Id__r.Address_2_text__c,
                       Merchant_Location_Id__r.Address_3_text__c,
                       Merchant_Location_Id__r.Parish_Province_State_list__c,
                       Merchant_Location_Id__r.Country_list__c
                FROM Case
                WHERE Id IN :serviceAssignmentIds
            ]);

            for (SerializedProduct serializedProduct : acceptedProducts) {
                Terminal_ID__c terminal = terminalMap.get(serializedProduct.Terminal_ID_TID_Id__c);
                Case caseRecord = null;
                if (terminal != null && terminal.Case__c != null) {
                    caseRecord = caseMap.get(terminal.Case__c);
                }

                ReturnedPOSDeviceWrapper acceptedDeviceWrapper = new ReturnedPOSDeviceWrapper(serializedProduct, terminal, caseRecord);
                devices.add(acceptedDeviceWrapper);
            }

            return devices;
        } catch (Exception e) {
            throw new ReturnedPOSDevicesControllerException('Error retrieving accepted returned POS devices: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static List<ReturnedPOSDeviceWrapper> searchReturnedPOSDevices(String searchTerm, String viewType) {
        try {
            List<ReturnedPOSDeviceWrapper> allDevices;

            if (viewType == 'accepted') {
                allDevices = getAcceptedReturnedPOSDevices();
            } else {
                allDevices = getReturnedPOSDevices();
            }

            if (String.isBlank(searchTerm)) {
                return allDevices;
            }

            List<ReturnedPOSDeviceWrapper> filteredDevices = new List<ReturnedPOSDeviceWrapper>();
            String lowerSearchTerm = searchTerm.toLowerCase();

            for (ReturnedPOSDeviceWrapper device : allDevices) {
                if ((device.serialNumber != null && device.serialNumber.toLowerCase().contains(lowerSearchTerm)) ||
                    (device.tid != null && device.tid.toLowerCase().contains(lowerSearchTerm)) ||
                    (device.merchantName != null && device.merchantName.toLowerCase().contains(lowerSearchTerm)) ||
                    (device.model != null && device.model.toLowerCase().contains(lowerSearchTerm)) ||
                    (device.bankName != null && device.bankName.toLowerCase().contains(lowerSearchTerm))) {
                    filteredDevices.add(device);
                }
            }

            return filteredDevices;

        } catch (Exception e) {
            throw new ReturnedPOSDevicesControllerException('Error searching returned devices: ' + e.getMessage() + ' ' + e.getStackTraceString());
        }
    }

    @AuraEnabled
    public static void confirmAcceptanceOfDevices(List<String> deviceIds) {
        try {
            List<SerializedProduct> devicesToProcess = [
                SELECT Id, Bank_Id__c, Bank_Id__r.Name, Product2Id, Terminal_ID_TID_Id__c, SerialNumber, ProductItemId, Status
                FROM SerializedProduct
                WHERE Id IN :deviceIds
            ];

            // Scenario 7: Process acceptance of returned devices
            List<SerializedProduct> devicesToUnprogram = new List<SerializedProduct>();
            List<ProductTransfer> transfersToUpdate = new List<ProductTransfer>();
            List<ProductTransferState> productTransferStatesToCreate = new List<ProductTransferState>();

            // Get bank-specific programming locations
            Set<Id> bankIds = new Set<Id>();

            for (SerializedProduct serializedProduct : devicesToProcess) {
                bankIds.add(serializedProduct.Bank_Id__c);
            }

            Map<Id, Schema.Location> bankProgrammingLocations = getBankProgrammingLocations(bankIds);

            Set<Id> productItemIds = new Set<Id>();
            for (SerializedProduct serializedProduct : devicesToProcess) {
                if (serializedProduct.ProductItemId != null) {
                    productItemIds.add(serializedProduct.ProductItemId);
                }
            }

            // Find existing ProductTransfer records for returned devices
            List<ProductTransfer> existingTransfers = [
                SELECT Id, SourceProductItemId, Status, Product2Id, DestinationLocationId
                FROM ProductTransfer
                WHERE SourceProductItemId IN :productItemIds
                AND Status = 'Returned'
                ORDER BY CreatedDate DESC
            ];

            Map<Id, ProductTransfer> productItemToTransferMap = new Map<Id, ProductTransfer>();
            for (ProductTransfer productTransfer : existingTransfers) {
                if (!productItemToTransferMap.containsKey(productTransfer.SourceProductItemId)) {
                    productItemToTransferMap.put(productTransfer.SourceProductItemId, productTransfer);
                }
            }

            for (SerializedProduct serializedProduct : devicesToProcess) {
                // Scenario 7: Automatically un-program devices
                serializedProduct.Substatus_list__c = 'Not Assigned';
                serializedProduct.Terminal_ID_TID_Id__c = null;

                // Find appropriate bank programming location
                Schema.Location targetLocation = bankProgrammingLocations.get(serializedProduct.Bank_Id__c);
                if (targetLocation == null) {
                    throw new ReturnedPOSDevicesControllerException('Programming location not found for bank: ' + serializedProduct.Bank_Id__r.Name);
                }

                // Update existing ProductTransfer to "Received" status
                ProductTransfer existingTransfer = productItemToTransferMap.get(serializedProduct.ProductItemId);
                System.debug('existingTransfer before: ' + existingTransfer);
                if (existingTransfer != null) {
                    existingTransfer.Status = 'Received';
                    existingTransfer.IsReceived = true;
                    existingTransfer.DestinationLocationId = targetLocation.Id;
                    existingTransfer.Description = 'Returned Device Accepted - ' + serializedProduct.SerialNumber;
                    existingTransfer.QuantityReceived = 1;
                    System.debug('existingTransfer after: ' + existingTransfer);
                    transfersToUpdate.add(existingTransfer);
                    
                    // Create ProductTransferState for returned device
                    ProductTransferState returnedState = new ProductTransferState(
                        ProductTransferId = existingTransfer.Id,
                        SerializedProductId = serializedProduct.Id,
                        Action = 'Receive',
                        TransferState = 'Available'
                    );
                    productTransferStatesToCreate.add(returnedState);
                }

                // Update SerializedProduct destination location
                serializedProduct.Destination_Location_Id__c = targetLocation.Id;
                devicesToUnprogram.add(serializedProduct);
            }

            // Update ProductTransferStates
            if (!productTransferStatesToCreate.isEmpty()) {
                insert productTransferStatesToCreate;
            }

            // Update ProductTransfers
            if (!transfersToUpdate.isEmpty()) {
                update transfersToUpdate;
            }

            // Update SerializedProducts (un-program and set destination)
            if (!devicesToUnprogram.isEmpty()) {
                update devicesToUnprogram;
            }
        } catch (Exception e) {
            System.debug('Error confirming acceptance of devices: ' + e.getMessage() + ' ' + e.getStackTraceString());
            throw new ReturnedPOSDevicesControllerException('Error confirming acceptance of devices: ' + e.getMessage());
        }
    }

    // Helper method to get current user's territories for viewing restrictions (Scenario 9)
    private static Set<String> getCurrentUserTerritories() {
        Set<String> userTerritories = new Set<String>();

        try {
            // Query FSL__User_Territory__c to get all territories assigned to current user
            List<FSL__User_Territory__c> userTerritoryRecords = [
                SELECT Id, FSL__Territory_Name__c
                FROM FSL__User_Territory__c
                WHERE FSL__User__c = :UserInfo.getUserId()
            ];

            for (FSL__User_Territory__c userTerritoryRecord : userTerritoryRecords) {
                userTerritories.add(userTerritoryRecord.FSL__Territory_Name__c);
            }
        } catch (Exception e) {
            // Show all devices if user doesn't have territory restriction.
        }

        return userTerritories;
    }

    // Helper method to get bank-specific programming locations
    private static Map<Id, Schema.Location> getBankProgrammingLocations(Set<Id> bankIds) {
        List<Schema.Location> programmingLocations = [
            SELECT Id, Name, Customer_Name_Id__c
            FROM Location
            WHERE LocationType = 'Programmer'
            AND Customer_Name_Id__c IN :bankIds
        ];

        Map<Id, Schema.Location> bankLocationMap = new Map<Id, Schema.Location>();
        for (Schema.Location location : programmingLocations) {
            bankLocationMap.put(location.Customer_Name_Id__c, location);
        }

        return bankLocationMap;
    }

    public class ReturnedPOSDevicesControllerException extends Exception { }
}