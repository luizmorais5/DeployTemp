public with sharing class ShippedPOSDevicesController {

    // Scenario 2: Get POS Devices available for territory shipment
    @AuraEnabled
    public static List<ShippedPOSDeviceWrapper> getPOSDevicesForShipment(String destination, String destinationType) {
        try {
            List<ShippedPOSDeviceWrapper> devicesForShipment = new List<ShippedPOSDeviceWrapper>();

            List<SerializedProduct> programmedDevices;
            if (destinationType == 'territory') {
                // Scenario 2: Query devices in "POS Devices for Territories" location
                programmedDevices = [
                    SELECT Id, SerialNumber, Product2.Name, Product2Id, Terminal_ID_TID_Id__c, Bank_Id__c, Bank_Id__r.Name, 
                           ProductItem.Location.Customer_Name_Id__c, ProductItem.Location.Name
                    FROM SerializedProduct
                    WHERE ProductItem.Location.Name = 'POS Devices for Territories'
                    AND ProductItem.Location.LocationType = 'Programmed devices'
                    AND Status = 'Available'
                ];
            } else {
                programmedDevices = [
                    SELECT Id, SerialNumber, Product2.Name, Product2Id, Terminal_ID_TID_Id__c, Bank_Id__c, Bank_Id__r.Name, 
                           ProductItem.Location.Customer_Name_Id__c
                    FROM SerializedProduct
                    WHERE ProductItem.Location.LocationType = 'Programmed devices'
                    AND Terminal_ID_TID_Id__c != null
                    AND Status = 'Available'
                ];
            }

            Set<Id> terminalIds = new Set<Id>();
            for (SerializedProduct serializedProduct : programmedDevices) {
                if (serializedProduct.Terminal_ID_TID_Id__c != null) {
                    terminalIds.add(serializedProduct.Terminal_ID_TID_Id__c);
                }
            }

            Map<Id, Terminal_ID__c> terminalMap = getTerminalMap(terminalIds);
            Map<Id, Case> caseMap = getCaseMapFromTerminals(terminalMap.values());

            for (SerializedProduct serializedProduct : programmedDevices) {
                Terminal_ID__c terminal = terminalMap.get(serializedProduct.Terminal_ID_TID_Id__c);
                Case caseRecord = null;
                if (terminal != null && terminal.Case__c != null) {
                    caseRecord = caseMap.get(terminal.Case__c);
                }

                ShippedPOSDeviceWrapper deviceWrapper = new ShippedPOSDeviceWrapper(serializedProduct, terminal, caseRecord);
                deviceWrapper.shipped = true;
                devicesForShipment.add(deviceWrapper);
            }

            return devicesForShipment;

        } catch (Exception e) {
            System.debug('Error retrieving POS devices for shipment: ' + e.getMessage());
            System.debug(e.getStackTraceString());
            throw new ShippedPOSDevicesControllerException('Error retrieving POS devices for shipment: ' + e.getMessage());
        }
    }

    // Scenario 6: Get shipped POS devices with territory filtering and access restrictions
    @AuraEnabled
    public static List<ShippedPOSDeviceWrapper> getShippedPOSDevices(String destination, String destinationType) {
        try {
            List<ShippedPOSDeviceWrapper> shippedDevices = new List<ShippedPOSDeviceWrapper>();
            Set<String> currentUserTerritories = getCurrentUserTerritories();

            List<SerializedProduct> shippedProducts;
            
            if (destinationType == 'territory' && !currentUserTerritories.isEmpty()) {
                // Scenario 9: Territory-based access restrictions for MSO Lead
                shippedProducts = [
                    SELECT Id, SerialNumber, Product2.Name, Product2Id, Terminal_ID_TID_Id__c, Bank_Id__r.Name
                    FROM SerializedProduct
                    WHERE Id IN (
                        SELECT SerializedProductId
                        FROM ProductTransferState
                        WHERE ProductTransfer.Status = 'Sent'
                        AND ProductTransfer.IsReceived = false
                    )
                    AND Terminal_ID_TID_Id__r.Service_Territory_text__c IN :currentUserTerritories
                ];
            } else {
                // Query SerializedProducts that have been shipped but not yet received
                shippedProducts = [
                    SELECT Id, SerialNumber, Product2.Name, Product2Id, Terminal_ID_TID_Id__c, Bank_Id__r.Name
                    FROM SerializedProduct
                    WHERE Id IN (
                        SELECT SerializedProductId
                        FROM ProductTransferState
                        WHERE ProductTransfer.Status = 'Sent'
                        AND ProductTransfer.IsReceived = false
                    )
                ];
            }

            Set<Id> terminalIds = new Set<Id>();
            for (SerializedProduct serializedProduct : shippedProducts) {
                if (serializedProduct.Terminal_ID_TID_Id__c != null) {
                    terminalIds.add(serializedProduct.Terminal_ID_TID_Id__c);
                }
            }

            Map<Id, Terminal_ID__c> terminalMap = getTerminalMap(terminalIds);
            Map<Id, Case> caseMap = getCaseMapFromTerminals(terminalMap.values());

            // Get shipment dates from ProductTransfer records
            Set<Id> serializedProductIds = new Set<Id>();
            for (SerializedProduct sp : shippedProducts) {
                serializedProductIds.add(sp.Id);
            }

            Map<Id, DateTime> shipmentDates = getShipmentDates(serializedProductIds);

            for (SerializedProduct serializedProduct : shippedProducts) {
                Terminal_ID__c terminal = terminalMap.get(serializedProduct.Terminal_ID_TID_Id__c);
                Case caseRecord = null;
                if (terminal != null && terminal.Case__c != null) {
                    caseRecord = caseMap.get(terminal.Case__c);
                }

                ShippedPOSDeviceWrapper deviceWrapper = new ShippedPOSDeviceWrapper(serializedProduct, terminal, caseRecord);
                deviceWrapper.shipped = true;
                deviceWrapper.received = true; // Scenario 6: checked by default
                
                // Scenario 6: Add date sent
                if (shipmentDates.containsKey(serializedProduct.Id)) {
                    deviceWrapper.dateSent = shipmentDates.get(serializedProduct.Id);
                }
                
                shippedDevices.add(deviceWrapper);
            }

            return shippedDevices;

        } catch (Exception e) {
            System.debug('Error getting shipped POS devices: ' + e.getMessage());
            System.debug(e.getStackTraceString());
            throw new ShippedPOSDevicesControllerException('Error retrieving shipped POS devices: ' + e.getMessage());
        }
    }

    // Scenario 8: Get received shipped POS devices with territory support
    @AuraEnabled
    public static List<ShippedPOSDeviceWrapper> getReceivedShippedPOSDevices(String destination, String destinationType) {
        try {
            List<ShippedPOSDeviceWrapper> receivedDevices = new List<ShippedPOSDeviceWrapper>();
            Set<String> currentUserTerritories = getCurrentUserTerritories();

            List<SerializedProduct> receivedProducts;
            
            if (destinationType == 'territory' && !currentUserTerritories.isEmpty()) {
                // Scenario 9: Territory-based access restrictions for MSO Lead
                receivedProducts = [
                    SELECT Id, SerialNumber, Product2.Name, Product2Id, Terminal_ID_TID_Id__c, Bank_Id__r.Name
                    FROM SerializedProduct
                    WHERE Id IN (
                        SELECT SerializedProductId
                        FROM ProductTransferState
                        WHERE ProductTransfer.Status = 'Received'
                    )
                    AND Terminal_ID_TID_Id__r.Service_Territory_text__c IN :currentUserTerritories
                ];
            } else {
                // Query SerializedProducts that have been shipped and received
                receivedProducts = [
                    SELECT Id, SerialNumber, Product2.Name, Product2Id, Terminal_ID_TID_Id__c, Bank_Id__r.Name
                    FROM SerializedProduct
                    WHERE Id IN (
                        SELECT SerializedProductId
                        FROM ProductTransferState
                        WHERE ProductTransfer.Status = 'Received'
                        AND ProductTransfer.ShipmentId != null
                    )
                    AND ProductItem.Location.Name LIKE '%POS Devices%'
                ];
            }

            Set<Id> terminalIds = new Set<Id>();
            for (SerializedProduct serializedProduct : receivedProducts) {
                if (serializedProduct.Terminal_ID_TID_Id__c != null) {
                    terminalIds.add(serializedProduct.Terminal_ID_TID_Id__c);
                }
            }

            Map<Id, Terminal_ID__c> terminalMap = getTerminalMap(terminalIds);
            Map<Id, Case> caseMap = getCaseMapFromTerminals(terminalMap.values());

            // Get receipt dates from ProductTransfer records
            Set<Id> serializedProductIds = new Set<Id>();
            for (SerializedProduct sp : receivedProducts) {
                serializedProductIds.add(sp.Id);
            }

            Map<Id, DateTime> receiptDates = getReceiptDates(serializedProductIds);

            for (SerializedProduct serializedProduct : receivedProducts) {
                Terminal_ID__c terminal = terminalMap.get(serializedProduct.Terminal_ID_TID_Id__c);
                Case caseRecord = null;
                if (terminal != null && terminal.Case__c != null) {
                    caseRecord = caseMap.get(terminal.Case__c);
                }

                ShippedPOSDeviceWrapper deviceWrapper = new ShippedPOSDeviceWrapper(serializedProduct, terminal, caseRecord);
                deviceWrapper.reship = false; // Scenario 8: unchecked by default
                deviceWrapper.reshipDestination = ''; // Scenario 8: empty pick list
                
                // Scenario 8: Add date received
                if (receiptDates.containsKey(serializedProduct.Id)) {
                    deviceWrapper.dateReceived = receiptDates.get(serializedProduct.Id);
                }
                
                receivedDevices.add(deviceWrapper);
            }

            return receivedDevices;

        } catch (Exception e) {
            System.debug('Error getting received shipped POS devices: ' + e.getMessage());
            System.debug(e.getStackTraceString());
            throw new ShippedPOSDevicesControllerException('Error retrieving received shipped POS devices: ' + e.getMessage());
        }
    }

    // Scenario 4: Search functionality across all device views
    @AuraEnabled
    public static List<ShippedPOSDeviceWrapper> searchPOSDevices(String searchTerm, String viewType, String destination, String destinationType) {
        try {
            List<ShippedPOSDeviceWrapper> allDevices;

            switch on viewType {
                when 'devices-for-shipment' {
                    allDevices = getPOSDevicesForShipment(destination, destinationType);
                }
                when 'shipped-devices' {
                    allDevices = getShippedPOSDevices(destination, destinationType);
                }
                when 'received-shipped-devices' {
                    allDevices = getReceivedShippedPOSDevices(destination, destinationType);
                }
                when else {
                    allDevices = new List<ShippedPOSDeviceWrapper>();
                }
            }

            if (String.isBlank(searchTerm)) {
                return allDevices;
            }

            List<ShippedPOSDeviceWrapper> filteredDevices = new List<ShippedPOSDeviceWrapper>();
            String lowerSearchTerm = searchTerm.toLowerCase();

            for (ShippedPOSDeviceWrapper device : allDevices) {
                if ((device.serialNumber != null && device.serialNumber.toLowerCase().contains(lowerSearchTerm)) ||
                    (device.tid != null && device.tid.toLowerCase().contains(lowerSearchTerm)) ||
                    (device.merchantName != null && device.merchantName.toLowerCase().contains(lowerSearchTerm)) ||
                    (device.model != null && device.model.toLowerCase().contains(lowerSearchTerm)) ||
                    (device.caseNumber != null && device.caseNumber.toLowerCase().contains(lowerSearchTerm))) {
                    filteredDevices.add(device);
                }
            }

            return filteredDevices;

        } catch (Exception e) {
            System.debug('Error searching POS devices: ' + e.getMessage());
            System.debug(e.getStackTraceString());
            throw new ShippedPOSDevicesControllerException('Error searching POS devices: ' + e.getMessage());
        }
    }

    // Scenario 5 & 6: Confirm shipment of POS devices with territory support
    @AuraEnabled
    public static void confirmShipment(List<String> deviceIds, String destination, String destinationType) {
        try {
            List<SerializedProduct> devicesToShip = [
                SELECT Id, Product2Id, Terminal_ID_TID_Id__c, SerialNumber, ProductItemId, Bank_Id__c, Bank_Id__r.Name, 
                       ProductItem.Location.Customer_Name_Id__c
                FROM SerializedProduct
                WHERE Id IN :deviceIds
            ];

            List<ProductTransfer> productTransfersToCreate = new List<ProductTransfer>();
            List<ProductTransferState> transferStatesToCreate = new List<ProductTransferState>();

            if (destinationType == 'territory') {
                // Scenario 5: Territory shipment logic
                List<Schema.Location> territoryLocations = getTerritoryPOSDevicesLocations(destination);
                
                if (territoryLocations.isEmpty()) {
                    throw new ShippedPOSDevicesControllerException('Territory location "' + destination + ' POS Devices" not found');
                }

                Schema.Location targetLocation = territoryLocations[0];

                for (SerializedProduct serializedProduct : devicesToShip) {
                    // Scenario 5: Create ProductTransfer record with State = 'Sent'
                    ProductTransfer productTransfer = new ProductTransfer();
                    productTransfer.SourceProductItemId = serializedProduct.ProductItemId;
                    productTransfer.Product2Id = serializedProduct.Product2Id;
                    productTransfer.DestinationLocationId = targetLocation.Id;
                    productTransfer.Status = 'Sent';
                    productTransfer.IsReceived = false;
                    productTransfer.QuantitySent = 1;
                    productTransfer.QuantityUnitOfMeasure = 'Each';
                    productTransfer.Description = 'Shipped to ' + destination + ' Territory - ' + serializedProduct.SerialNumber;
                    productTransfer.CreatedDate = System.now();
                    productTransfersToCreate.add(productTransfer);
                }
            } else {
                // Existing hub logic
                Set<Id> deviceBankIds = new Set<Id>();
                for (SerializedProduct serializedProduct : devicesToShip) {
                    if (serializedProduct.Bank_Id__c != null) {
                        deviceBankIds.add(serializedProduct.Bank_Id__c);
                    }
                }

                List<Schema.Location> locations = [
                    SELECT Id, Name, Customer_Name_Id__c
                    FROM Location
                    WHERE Name LIKE :('%' + destination + '%')
                    AND LocationType = 'Programmed devices'
                    AND Customer_Name_Id__c IN :deviceBankIds
                    LIMIT 1
                ];

                Map<Id, Schema.Location> locationByBankId = new Map<Id, Schema.Location>();
                for (Schema.Location location : locations) {
                    locationByBankId.put(location.Customer_Name_Id__c, location);
                }

                for (SerializedProduct serializedProduct : devicesToShip) {
                    Schema.Location targetLocation = locationByBankId.get(serializedProduct.Bank_Id__c);

                    if (targetLocation == null) {
                        String deviceBankName = serializedProduct.Bank_Id__r.Name;
                        throw new ShippedPOSDevicesControllerException('Target location not found for destination: ' + destination + ' and bank: ' + deviceBankName);
                    }

                    ProductTransfer productTransfer = new ProductTransfer();
                    productTransfer.SourceProductItemId = serializedProduct.ProductItemId;
                    productTransfer.Product2Id = serializedProduct.Product2Id;
                    productTransfer.DestinationLocationId = targetLocation.Id;
                    productTransfer.Status = 'Sent';
                    productTransfer.IsReceived = false;
                    productTransfer.QuantitySent = 1;
                    productTransfer.Description = 'Shipped to ' + destination + ' - ' + serializedProduct.SerialNumber;
                    productTransfersToCreate.add(productTransfer);
                }
            }

            // Insert ProductTransfer records
            if (!productTransfersToCreate.isEmpty()) {
                insert productTransfersToCreate;

                // Create corresponding ProductTransferState records
                for (Integer i = 0; i < productTransfersToCreate.size(); i++) {
                    ProductTransferState transferState = new ProductTransferState();
                    transferState.ProductTransferId = productTransfersToCreate[i].Id;
                    transferState.SerializedProductId = devicesToShip[i].Id;
                    transferState.Action = 'Send';
                    transferState.TransferState = 'Sent';
                    transferStatesToCreate.add(transferState);
                }

                if (!transferStatesToCreate.isEmpty()) {
                    insert transferStatesToCreate;
                }
            }

        } catch (Exception e) {
            System.debug('Error confirming shipment: ' + e.getMessage());
            System.debug(e.getStackTraceString());
            throw new ShippedPOSDevicesControllerException('Error confirming shipment: ' + e.getMessage());
        }
    }

    // Scenario 7: Confirm receipt of shipped POS devices with territory support
    @AuraEnabled
    public static void confirmReceipt(List<String> deviceIds, String destination, String destinationType) {
        try {
            List<SerializedProduct> devicesToReceive = [
                SELECT Id, ProductItemId, SerialNumber, Product2Id
                FROM SerializedProduct
                WHERE Id IN :deviceIds
            ];

            Set<Id> productItemIds = new Set<Id>();
            for (SerializedProduct serializedProduct : devicesToReceive) {
                if (serializedProduct.ProductItemId != null) {
                    productItemIds.add(serializedProduct.ProductItemId);
                }
            }

            // Find existing ProductTransfer records for shipped devices
            List<ProductTransfer> existingTransfers = [
                SELECT Id, SourceProductItemId, Status, IsReceived, DestinationLocationId, Description
                FROM ProductTransfer
                WHERE SourceProductItemId IN :productItemIds
                AND Status = 'Sent'
                AND IsReceived = false
                ORDER BY CreatedDate DESC
            ];

            Map<Id, ProductTransfer> productItemToTransferMap = new Map<Id, ProductTransfer>();
            for (ProductTransfer productTransfer : existingTransfers) {
                if (!productItemToTransferMap.containsKey(productTransfer.SourceProductItemId)) {
                    productItemToTransferMap.put(productTransfer.SourceProductItemId, productTransfer);
                }
            }

            List<ProductTransfer> updatedTransfers = new List<ProductTransfer>();
            List<ProductTransferState> newTransferStates = new List<ProductTransferState>();
            List<SerializedProduct> serializedProductsToUpdate = new List<SerializedProduct>();

            for (SerializedProduct serializedProduct : devicesToReceive) {
                ProductTransfer existingTransfer = productItemToTransferMap.get(serializedProduct.ProductItemId);
                
                if (existingTransfer != null) {
                    // Scenario 7: Update ProductTransfer state to "Received"
                    existingTransfer.Status = 'Received';
                    existingTransfer.IsReceived = true;
                    existingTransfer.QuantityReceived = 1;
                    existingTransfer.Description += ' - Received';
                    updatedTransfers.add(existingTransfer);

                    // Create new ProductTransferState for receipt
                    ProductTransferState receiptState = new ProductTransferState();
                    receiptState.ProductTransferId = existingTransfer.Id;
                    receiptState.SerializedProductId = serializedProduct.Id;
                    receiptState.Action = 'Receive';
                    receiptState.TransferState = 'Available';
                    newTransferStates.add(receiptState);

                    // Scenario 7: Update SerializedProduct location to territory location
                    if (destinationType == 'territory') {
                        serializedProduct.Destination_Location_Id__c = existingTransfer.DestinationLocationId;
                        serializedProductsToUpdate.add(serializedProduct);
                    }
                }
            }

            if (!newTransferStates.isEmpty()) {
                insert newTransferStates;
            }

            if (!updatedTransfers.isEmpty()) {
                update updatedTransfers;
            }

            if (!serializedProductsToUpdate.isEmpty()) {
                Database.update(serializedProductsToUpdate, false);
            }

        } catch (Exception e) {
            System.debug('Error confirming receipt: ' + e.getMessage());
            System.debug(e.getStackTraceString());
            throw new ShippedPOSDevicesControllerException('Error confirming receipt: ' + e.getMessage());
        }
    }

    // Helper method to get terminal information
    private static Map<Id, Terminal_ID__c> getTerminalMap(Set<Id> terminalIds) {
        return new Map<Id, Terminal_ID__c>([
            SELECT Id, Name, SIM_Card_Id__c, SIM_Card_2_Id__c, Case__c, Service_Territory_text__c
            FROM Terminal_ID__c
            WHERE Id IN :terminalIds
        ]);
    }

    // Helper method to get case information from terminals
    private static Map<Id, Case> getCaseMapFromTerminals(List<Terminal_ID__c> terminals) {
        Set<Id> caseIds = new Set<Id>();
        for (Terminal_ID__c terminal : terminals) {
            if (terminal.Case__c != null) {
                caseIds.add(terminal.Case__c);
            }
        }

        return new Map<Id, Case>([
            SELECT Id, Account.Name, CaseNumber, Service_Territory__c,
                   Merchant_Location_Id__r.Address_1_text__c,
                   Merchant_Location_Id__r.Address_2_text__c,
                   Merchant_Location_Id__r.Address_3_text__c,
                   Merchant_Location_Id__r.Parish_Province_State_list__c,
                   Merchant_Location_Id__r.Country_list__c
            FROM Case
            WHERE Id IN :caseIds
        ]);
    }

    // Helper method to get territory POS devices locations
    private static List<Schema.Location> getTerritoryPOSDevicesLocations(String territoryName) {
        return [
            SELECT Id, Name
            FROM Location
            WHERE Name = :(territoryName + ' POS Devices')
            AND LocationType = 'Programmed devices'
            LIMIT 1
        ];
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
            // Return empty set if user doesn't have territory restrictions
            System.debug('No territory restrictions found for user: ' + e.getMessage());
        }

        return userTerritories;
    }

    // Helper method to get shipment dates
    private static Map<Id, DateTime> getShipmentDates(Set<Id> serializedProductIds) {
        Map<Id, DateTime> shipmentDates = new Map<Id, DateTime>();
        
        List<ProductTransferState> transferStates = [
            SELECT SerializedProductId, ProductTransfer.CreatedDate
            FROM ProductTransferState
            WHERE SerializedProductId IN :serializedProductIds
            AND Action = 'Send'
            AND TransferState = 'Sent'
            ORDER BY CreatedDate DESC
        ];

        for (ProductTransferState state : transferStates) {
            if (!shipmentDates.containsKey(state.SerializedProductId)) {
                shipmentDates.put(state.SerializedProductId, state.ProductTransfer.CreatedDate);
            }
        }

        return shipmentDates;
    }

    // Helper method to get receipt dates
    private static Map<Id, DateTime> getReceiptDates(Set<Id> serializedProductIds) {
        Map<Id, DateTime> receiptDates = new Map<Id, DateTime>();
        
        List<ProductTransferState> transferStates = [
            SELECT SerializedProductId, CreatedDate
            FROM ProductTransferState
            WHERE SerializedProductId IN :serializedProductIds
            AND Action = 'Receive'
            AND TransferState = 'Available'
            ORDER BY CreatedDate DESC
        ];

        for (ProductTransferState state : transferStates) {
            if (!receiptDates.containsKey(state.SerializedProductId)) {
                receiptDates.put(state.SerializedProductId, state.CreatedDate);
            }
        }

        return receiptDates;
    }

    public class ShippedPOSDevicesControllerException extends Exception { }
}