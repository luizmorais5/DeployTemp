public with sharing class ProgrammedPOSDevicesController {

    @AuraEnabled
    public static List<ProgrammedPOSDeviceWrapper> getProgrammedPOSDevices() {
        try {
            Boolean isDualRole = hasDualProgrammerLogisticianRole();
            
            // Return empty list for dual-role users
            if (isDualRole) {
                return new List<ProgrammedPOSDeviceWrapper>();
            }

            List<ProgrammedPOSDeviceWrapper> devices = new List<ProgrammedPOSDeviceWrapper>();
            
            List<SerializedProduct> serializedProducts = [
                SELECT Id, SerialNumber, Product2.Name, Product2Id, Picked_Up__c, Terminal_ID_TID_Id__c
                FROM SerializedProduct 
                WHERE Substatus_list__c = 'Assigned to a Terminal ID'
                AND ProductItem.Location.LocationType = 'Programmer'
                AND Picked_Up__c = false
                AND Returned__c = false
            ];

            Set<Id> terminalIds = new Set<Id>();
            for (SerializedProduct sp : serializedProducts) {
                if (sp.Terminal_ID_TID_Id__c != null) {
                    terminalIds.add(sp.Terminal_ID_TID_Id__c);
                }
            }
            
            Map<Id, Terminal_ID__c> terminalMap = new Map<Id, Terminal_ID__c>([
                SELECT Id, Name, SIM_Card_Id__c, SIM_Card_2_Id__c, Work_Order_ID__c
                FROM Terminal_ID__c 
                WHERE Id IN :terminalIds
            ]);
            
            Set<Id> workOrderIds = new Set<Id>();
            for (Terminal_ID__c terminal : terminalMap.values()) {
                if (terminal.Work_Order_ID__c != null) {
                    workOrderIds.add(terminal.Work_Order_ID__c);
                }
            }
            
            Map<Id, Case> caseMap = new Map<Id, Case>([
                SELECT Id, Account.Name, CaseNumber, Service_Territory__c,
                       Merchant_Location_Id__r.Address_1_text__c,
                       Merchant_Location_Id__r.Address_2_text__c,
                       Merchant_Location_Id__r.Address_3_text__c,
                       Merchant_Location_Id__r.Parish_Province_State_list__c,
                       Merchant_Location_Id__r.Country_list__c, Work_Order_ID__c
                FROM Case 
                WHERE Work_Order_ID__c IN :workOrderIds
            ]);
            
            Map<Id, Case> workOrderToCaseMap = new Map<Id, Case>();
            for (Case caseRecord : caseMap.values()) {
                workOrderToCaseMap.put(caseRecord.Work_Order_ID__c, caseRecord);
            }
            
            for (SerializedProduct serializedProduct : serializedProducts) {
                Terminal_ID__c terminal = terminalMap.get(serializedProduct.Terminal_ID_TID_Id__c);
                Case caseRecord = null;
                if (terminal != null && terminal.Work_Order_ID__c != null) {
                    caseRecord = workOrderToCaseMap.get(terminal.Work_Order_ID__c);
                }
                
                ProgrammedPOSDeviceWrapper programmedPOSDeviceWrapper = new ProgrammedPOSDeviceWrapper(serializedProduct, terminal, caseRecord);
                programmedPOSDeviceWrapper.received = true;
                programmedPOSDeviceWrapper.returnToProgrammer = false;
                devices.add(programmedPOSDeviceWrapper);
            }
            
            return devices;
            
        } catch (Exception e) {
            System.debug('Error retrieving programmed POS devices: ' + e.getMessage());
            System.debug('Error retrieving programmed POS devices: ' + e.getStackTraceString());
            throw new ProgrammedPOSDevicesControllerException('Error retrieving programmed POS devices: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static List<ProgrammedPOSDeviceWrapper> getReceivedProgrammedPOSDevices() {
        try {
            Boolean isDualRole = hasDualProgrammerLogisticianRole();
            
            // Return empty list for dual-role users
            if (isDualRole) {
                return new List<ProgrammedPOSDeviceWrapper>();
            }
            
            List<ProgrammedPOSDeviceWrapper> devices = new List<ProgrammedPOSDeviceWrapper>();
            
            List<SerializedProduct> serializedProducts = [
                SELECT Id, SerialNumber, Product2.Name, Product2Id, Logistic_Status__c, Terminal_ID_TID_Id__c, Picked_Up__c, ProductItemId
                FROM SerializedProduct 
                WHERE Substatus_list__c = 'Assigned to a Terminal ID'
                AND ProductItem.Location.LocationType = 'Programmed devices'
                AND Returned__c = false
            ];
            
            Set<Id> terminalIds = new Set<Id>();
            Set<Id> productItemIds = new Set<Id>();
            for (SerializedProduct sp : serializedProducts) {
                if (sp.Terminal_ID_TID_Id__c != null) {
                    terminalIds.add(sp.Terminal_ID_TID_Id__c);
                }
                if (sp.ProductItemId != null) {
                    productItemIds.add(sp.ProductItemId);
                }
            }
            
            Map<Id, Terminal_ID__c> terminalMap = new Map<Id, Terminal_ID__c>([
                SELECT Id, Name, SIM_Card_Id__c, SIM_Card_2_Id__c, Work_Order_ID__c
                FROM Terminal_ID__c 
                WHERE Id IN :terminalIds
            ]);
            
            Set<Id> workOrderIds = new Set<Id>();
            for (Terminal_ID__c terminal : terminalMap.values()) {
                if (terminal.Work_Order_ID__c != null) {
                    workOrderIds.add(terminal.Work_Order_ID__c);
                }
            }
            
            Map<Id, Case> caseById = new Map<Id, Case>([
                SELECT Id, Account.Name, CaseNumber, Service_Territory__c,
                       Merchant_Location_Id__r.Address_1_text__c,
                       Merchant_Location_Id__r.Address_2_text__c,
                       Merchant_Location_Id__r.Address_3_text__c,
                       Merchant_Location_Id__r.Parish_Province_State_list__c,
                       Merchant_Location_Id__r.Country_list__c,
                       Work_Order_ID__c
                FROM Case 
                WHERE Work_Order_ID__c IN :workOrderIds
            ]);
            
            Map<Id, Case> caseByWorkOrderId = new Map<Id, Case>();
            for (Case caseRecord : caseById.values()) {
                caseByWorkOrderId.put(caseRecord.Work_Order_ID__c, caseRecord);
            }
            
            // Get Received ProductTransfer records
            Map<Id, ProductTransfer> productTransferMap = new Map<Id, ProductTransfer>();
            List<ProductTransfer> productTransfers = [
                SELECT Id, SourceProductItemId, LastModifiedDate, IsReceived
                FROM ProductTransfer
                WHERE SourceProductItemId IN :productItemIds
                ORDER BY LastModifiedDate DESC
            ];
            
            for (ProductTransfer productTransfer : productTransfers) {
                if (!productTransferMap.containsKey(productTransfer.SourceProductItemId)) {
                    productTransferMap.put(productTransfer.SourceProductItemId, productTransfer);
                }
            }
            
            for (SerializedProduct serializedProduct : serializedProducts) {
                Terminal_ID__c terminal = terminalMap.get(serializedProduct.Terminal_ID_TID_Id__c);
                Case caseRecord = null;
                if (terminal != null && terminal.Work_Order_ID__c != null) {
                    caseRecord = caseByWorkOrderId.get(terminal.Work_Order_ID__c);
                }
                
                ProgrammedPOSDeviceWrapper programmedPOSDeviceWrapper = new ProgrammedPOSDeviceWrapper(serializedProduct, terminal, caseRecord);
                programmedPOSDeviceWrapper.isPickedUp = serializedProduct.Picked_Up__c;
                
                // Set received date from ProductTransfer if available
                ProductTransfer productTransfer = productTransferMap.get(serializedProduct.ProductItemId);

                if (productTransfer != null && productTransfer.IsReceived) {
                    programmedPOSDeviceWrapper.dateReceived = productTransfer.LastModifiedDate.format('MM/dd/yyyy');
                }
                
                devices.add(programmedPOSDeviceWrapper);
            }
            
            return devices;
            
        } catch (Exception e) {
            System.debug('Error retrieving received programmed POS devices: ' + e.getMessage());
            System.debug('Error retrieving received programmed POS devices: ' + e.getStackTraceString());
            throw new ProgrammedPOSDevicesControllerException('Error retrieving received programmed POS devices: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static List<ProgrammedPOSDeviceWrapper> searchProgrammedPOSDevices(String searchTerm, String viewType) {
        try {
            List<ProgrammedPOSDeviceWrapper> allDevices;
            
            if (viewType == 'received') {
                allDevices = getReceivedProgrammedPOSDevices();
            } else {
                allDevices = getProgrammedPOSDevices();
            }
            
            if (String.isBlank(searchTerm)) {
                return allDevices;
            }
            
            List<ProgrammedPOSDeviceWrapper> filteredDevices = new List<ProgrammedPOSDeviceWrapper>();
            String lowerSearchTerm = searchTerm.toLowerCase();
            
            for (ProgrammedPOSDeviceWrapper device : allDevices) {
                if ((device.serialNumber != null && device.serialNumber.toLowerCase().contains(lowerSearchTerm)) ||
                    (device.tid != null && device.tid.toLowerCase().contains(lowerSearchTerm)) ||
                    (device.merchantName != null && device.merchantName.toLowerCase().contains(lowerSearchTerm)) ||
                    (device.model != null && device.model.toLowerCase().contains(lowerSearchTerm))) {
                    filteredDevices.add(device);
                }
            }
            
            return filteredDevices;

        } catch (Exception e) {
            System.debug('Error searching devices: ' + e.getMessage());
            System.debug('Error searching devices: ' + e.getStackTraceString());
            throw new ProgrammedPOSDevicesControllerException('Error searching devices: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static void confirmReceiptOfDevices(List<String> deviceIds) {
        try {
            List<SerializedProduct> devicesToUpdate = [
                SELECT Id, Bank_Id__c, Product2Id, Terminal_ID_TID_Id__c, SerialNumber, ProductItemId, Status
                FROM SerializedProduct 
                WHERE Id IN :deviceIds
            ];

            Set<Id> terminalIds = new Set<Id>();
            Set<Id> productItemIds = new Set<Id>();
            for (SerializedProduct serializedProduct : devicesToUpdate) {
                if (serializedProduct.Terminal_ID_TID_Id__c != null) {
                    terminalIds.add(serializedProduct.Terminal_ID_TID_Id__c);
                }
                if (serializedProduct.ProductItemId != null) {
                    productItemIds.add(serializedProduct.ProductItemId);
                }
            }

            // Scenario 9: Find existing ProductTransfer records created during programming
            List<ProductTransfer> existingProductTransfers = [
                SELECT Id, SourceProductItemId, Status, Product2Id
                FROM ProductTransfer
                WHERE SourceProductItemId IN :productItemIds
                AND Status != 'Received'
                ORDER BY CreatedDate DESC
            ];

            Map<Id, ProductTransfer> productItemToTransferMap = new Map<Id, ProductTransfer>();
            for (ProductTransfer productTransfer : existingProductTransfers) {
                if (!productItemToTransferMap.containsKey(productTransfer.SourceProductItemId)) {
                    productItemToTransferMap.put(productTransfer.SourceProductItemId, productTransfer);
                }
            }
            
            Map<Id, Terminal_ID__c> terminalMap = new Map<Id, Terminal_ID__c>([
                SELECT Id, Work_Order_ID__c
                FROM Terminal_ID__c 
                WHERE Id IN :terminalIds
            ]);
            
            Set<Id> workOrderIds = new Set<Id>();
            for (Terminal_ID__c terminal : terminalMap.values()) {
                if (terminal.Work_Order_ID__c != null) {
                    workOrderIds.add(terminal.Work_Order_ID__c);
                }
            }
            
            Map<Id, Case> caseMap = new Map<Id, Case>([
                SELECT Id, Work_Order_ID__c, AssignedTerritoryHub__c,
                       Merchant_Location_Id__r.Parish_Province_State_list__c
                FROM Case 
                WHERE Work_Order_ID__c IN :workOrderIds
            ]);
            
            Map<Id, Case> workOrderToCaseMap = new Map<Id, Case>();
            for (Case caseRecord : caseMap.values()) {
                workOrderToCaseMap.put(caseRecord.Work_Order_ID__c, caseRecord);
            }
            
            List<Schema.Location> shipmentLocations = [
                SELECT Id 
                FROM Location 
                WHERE Name = 'Programmed POS Devices for Shipment' 
                AND LocationType = 'Programmed devices'
            ];
            
            Schema.Location shipmentLocation = shipmentLocations.isEmpty() ? null : shipmentLocations.get(0);

            Map<Id, ServiceTerritory> serviceTerritoryById = new Map<Id, ServiceTerritory>([
                SELECT Id, Name
                FROM ServiceTerritory
                WHERE IsActive = true
            ]);

            List<SerializedProduct> serializedProductsToChangeLocation = new List<SerializedProduct>();
            List<SerializedProduct> serializedProductsToUpdate = new List<SerializedProduct>();
            List<ProductTransfer> productTransfersToCreate = new List<ProductTransfer>();
            List<ProductTransferState> productTransferStatesToCreate = new List<ProductTransferState>();
            
            // Scenario 9: Lists for updating existing ProductTransfer records
            List<ProductTransfer> existingTransfersToUpdate = new List<ProductTransfer>();
            List<ProductTransferState> receivedStatesToCreate = new List<ProductTransferState>();

            // Define the parishes for Kingston Hub (No Territory Hub Assigned)
            Set<String> kingstonHubParishes = new Set<String>{
                'Kingston', 'St. Andrew', 'St. Catherine', 'Clarendon', 
                'St. Thomas', 'Portland', 'St. Ann'
            };

            // Check if user has dual Programmer/Logistician role
            Boolean isDualRole = hasDualProgrammerLogisticianRole();

            for (SerializedProduct serializedProduct : devicesToUpdate) {
                Terminal_ID__c terminal = terminalMap.get(serializedProduct.Terminal_ID_TID_Id__c);

                if (terminal == null) {
                    throw new ProgrammedPOSDevicesControllerException('Terminal not found for device: ' + serializedProduct.SerialNumber);
                }

                Case caseRecord = workOrderToCaseMap.get(terminal.Work_Order_ID__c);

                if (caseRecord == null) {
                    throw new ProgrammedPOSDevicesControllerException('Case not found for device: ' + serializedProduct.SerialNumber);
                }

                ServiceTerritory assignedTerritoryHub = serviceTerritoryById.get(caseRecord.AssignedTerritoryHub__c);
                String merchantParish = caseRecord.Merchant_Location_Id__r?.Parish_Province_State_list__c;

                // Scenario 9: Update existing ProductTransfer to "Received" for all scenarios (if not dual role)
                if (!isDualRole) {
                    ProductTransfer existingTransfer = productItemToTransferMap.get(serializedProduct.ProductItemId);
                    if (existingTransfer != null) {
                        existingTransfer.Status = 'Received';
                        existingTransfersToUpdate.add(existingTransfer);

                        // Create ProductTransferState record for "Received" status
                        ProductTransferState receivedState = new ProductTransferState();
                        receivedState.ProductTransferId = existingTransfer.Id;
                        receivedState.SerializedProductId = serializedProduct.Id;
                        receivedState.Action = 'Receive';
                        receivedState.TransferState = 'Sent';
                        receivedStatesToCreate.add(receivedState);
                    }
                }

                // Scenario 1: For dual-role users, no Product Transfer should be created
                if (isDualRole) {
                    // Simply update the device location without creating transfers
                    serializedProductsToChangeLocation.add(serializedProduct);
                    continue;
                }

                // Scenario 5: No Territory Hub Assigned + Kingston Hub Parishes
                if (assignedTerritoryHub == null && kingstonHubParishes.contains(merchantParish)) {
                    serializedProductsToChangeLocation.add(serializedProduct);
                } 
                // Scenario 6: Territory Hub is Kingston
                else if (assignedTerritoryHub != null && assignedTerritoryHub.Name == 'Kingston') {
                    serializedProductsToChangeLocation.add(serializedProduct);
                }
                // Scenario 8: Territory hub is St. James or Manchester
                else if (assignedTerritoryHub != null && (assignedTerritoryHub.Name == 'St. James' || assignedTerritoryHub.Name == 'Manchester')) {
                    if (shipmentLocation != null) {
                        // Create ProductTransfer for St. James/Manchester devices
                        ProductTransfer productTransfer = new ProductTransfer();
                        productTransfer.SourceProductItemId = serializedProduct.ProductItemId;
                        productTransfer.DestinationLocationId = shipmentLocation.Id;
                        productTransfer.Product2Id = serializedProduct.Product2Id;
                        productTransfer.QuantitySent = 1;
                        productTransfer.QuantityUnitOfMeasure = 'Each';
                        productTransfer.Status = 'Ready For Pickup';
                        productTransfer.Description = 'Transfer to Shipment Location - ' + serializedProduct.SerialNumber;
                        productTransfersToCreate.add(productTransfer);
                        
                        serializedProduct.Destination_Location_Id__c = shipmentLocation.Id;
                        serializedProductsToUpdate.add(serializedProduct);
                    } else {
                        throw new ProgrammedPOSDevicesControllerException('Shipment location "Programmed POS Devices for Shipment" not found');
                    }
                }
            }

            // Scenario 9: Update existing ProductTransfer records to "Received" (only for non-dual-role users)
            if (!isDualRole && !existingTransfersToUpdate.isEmpty()) {
                update existingTransfersToUpdate;
            }

            // Scenario 9: Create ProductTransferState records for "Received" status (only for non-dual-role users)
            if (!isDualRole && !receivedStatesToCreate.isEmpty()) {
                insert receivedStatesToCreate;
            }

            // Insert new ProductTransfers for St. James/Manchester devices (only for non-dual-role users)
            if (!isDualRole && !productTransfersToCreate.isEmpty()) {
                insert productTransfersToCreate;
                
                // Create ProductTransferState records for new transfers
                for (Integer i = 0; i < productTransfersToCreate.size(); i++) {
                    ProductTransfer pt = productTransfersToCreate[i];
                    SerializedProduct sp = serializedProductsToUpdate[i];
                    
                    ProductTransferState productTransferState = new ProductTransferState();
                    productTransferState.ProductTransferId = pt.Id;
                    productTransferState.SerializedProductId = sp.Id;
                    productTransferState.Action = 'Send';
                    productTransferState.TransferState = 'Sent';
                    productTransferStatesToCreate.add(productTransferState);
                }
                
                if (!productTransferStatesToCreate.isEmpty()) {
                    insert productTransferStatesToCreate;
                }
                
                // Update ProductTransfer to mark as sent
                for (ProductTransfer pt : productTransfersToCreate) {
                    pt.IsSent = true;
                }

                update productTransfersToCreate;
            }

            if (!serializedProductsToChangeLocation.isEmpty()) {
                SerializedProductDomain.changeProgrammedDeviceLocation(serializedProductsToChangeLocation);
            }

            if (!serializedProductsToUpdate.isEmpty()) {
                update serializedProductsToUpdate;
            }
        } catch (Exception e) {
            System.debug('Error confirming receipt of devices: ' + e.getMessage());
            System.debug('Error confirming receipt of devices: ' + e.getStackTraceString());
            throw new ProgrammedPOSDevicesControllerException('Error confirming receipt of devices: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static void returnDevicesToProgrammer(List<String> deviceIds) {
        try {
            List<SerializedProduct> devicesToUpdate = [
                SELECT Id, Bank_Id__c, Bank_Id__r.Name, Product2Id, ProductItemId, Status
                FROM SerializedProduct 
                WHERE Id IN :deviceIds
            ];
            
            Set<Id> deviceBankIds = new Set<Id>();

            for (SerializedProduct serializedProduct : devicesToUpdate) {
                if (serializedProduct.Bank_Id__c != null) {
                    deviceBankIds.add(serializedProduct.Bank_Id__c);
                }
            }

            List<Schema.Location> locations = [
                SELECT Id, Name, Customer_Name_Id__c
                FROM Location
                WHERE LocationType = 'Warehouse'
                AND Customer_Name_Id__c IN :deviceBankIds
            ];

            Map<Id, Schema.Location> locationByBankId = new Map<Id, Schema.Location>();
            for (Schema.Location location : locations) {
                locationByBankId.put(location.Customer_Name_Id__c, location);
            }
            
            List<ProductTransfer> productTransfersToCreate = new List<ProductTransfer>();
            List<ProductTransferState> productTransferStatesToCreate = new List<ProductTransferState>();
            Map<Id, ProductTransfer> productTransferBySerializedProductId = new Map<Id, ProductTransfer>();

            // Create ProductTransfer records following flow logic
            for (SerializedProduct serializedProduct : devicesToUpdate) {
                Schema.Location returnLocation = locationByBankId.get(serializedProduct.Bank_Id__c);

                if (returnLocation == null) {
                    throw new ProgrammedPOSDevicesControllerException('Return location not found for bank: ' + serializedProduct.Bank_Id__r.Name);
                }

                serializedProduct.Returned__c = true;
                serializedProduct.Destination_Location_Id__c = returnLocation.Id;

                ProductTransfer productTransfer = new ProductTransfer();
                productTransfer.SourceProductItemId = serializedProduct.ProductItemId;
                productTransfer.DestinationLocationId = returnLocation.Id;
                productTransfer.Product2Id = serializedProduct.Product2Id;
                productTransfer.QuantitySent = 1;
                productTransfer.QuantityUnitOfMeasure = 'Each';
                productTransfer.Status = 'Ready For Pickup';
                productTransfer.Description = 'Return to Programming Team - ' + serializedProduct.Id;
                productTransferBySerializedProductId.put(serializedProduct.Id, productTransfer);
            }

            update devicesToUpdate;

            if (!productTransferBySerializedProductId.isEmpty()) {
                insert productTransferBySerializedProductId.values();
                
                // Create ProductTransferState records
                for (Id serializedProductId : productTransferBySerializedProductId.keySet()) {
                    ProductTransfer productTransfer = productTransferBySerializedProductId.get(serializedProductId);
                    
                    ProductTransferState productTransferState = new ProductTransferState();
                    productTransferState.ProductTransferId = productTransfer.Id;
                    productTransferState.SerializedProductId = serializedProductId;
                    productTransferState.Action = 'Send';
                    productTransferState.TransferState = 'Sent';
                    productTransferStatesToCreate.add(productTransferState);
                }
                
                if (!productTransferStatesToCreate.isEmpty()) {
                    insert productTransferStatesToCreate;
                }
                
                // Need to set IsSent to true after inserting product transfers. 
                // Otherwise we get an exception:
                // "To send a product transfer, you need permission to read serialized products. Ask your Salesforce admin for help"
                for (Id serializedProductId : productTransferBySerializedProductId.keySet()) {
                    ProductTransfer productTransfer = productTransferBySerializedProductId.get(serializedProductId);
                    productTransfer.IsSent = true;
                }

                update productTransferBySerializedProductId.values();
            }
            
        } catch (Exception e) {
            System.debug('Error returning devices to programmer: ' + e.getMessage());
            System.debug(e.getStackTraceString());
            throw new ProgrammedPOSDevicesControllerException('Error returning devices to programmer: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static Boolean hasDualProgrammerLogisticianRole() {
        try {
            // Get all skills for the current user
            List<ServiceResourceSkill> serviceResourceSkills = [
                SELECT Id, Skill.DeveloperName 
                FROM ServiceResourceSkill 
                WHERE ServiceResource.RelatedRecordId = :UserInfo.getUserId()
            ];
            
            Boolean hasProgrammerSkill = false;
            Boolean hasLogisticianSkill = false;
            
            for (ServiceResourceSkill serviceResourceSkill : serviceResourceSkills) {
                if (serviceResourceSkill.Skill.DeveloperName.contains('Programmer')) {
                    hasProgrammerSkill = true;
                } else if (serviceResourceSkill.Skill.DeveloperName.contains('Logistician')) {
                    hasLogisticianSkill = true;
                }
            }
            
            return hasProgrammerSkill && hasLogisticianSkill;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error checking dual role: ' + e.getMessage());
        }
    }

    public class ProgrammedPOSDevicesControllerException extends Exception { }
}