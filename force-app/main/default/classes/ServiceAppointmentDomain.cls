public class ServiceAppointmentDomain {
    
    public static void changeAssignedResource(List<ServiceAppointment> lstServiceAppointment, Map<Id, ServiceAppointment> oldMap){
        List<ServiceAppointment> lstServiceAppointmentProcess = new List<ServiceAppointment>();
        for (ServiceAppointment appointment : lstServiceAppointment) {
            ServiceAppointment oldAppointment = oldMap.get(appointment.Id);
            
            if (appointment.FSSK__FSK_Assigned_Service_Resource__c != oldAppointment.FSSK__FSK_Assigned_Service_Resource__c) {
                lstServiceAppointmentProcess.add(appointment);
            }
        }

        if(!lstServiceAppointmentProcess.isEmpty()){
            changeAssignedResource(lstServiceAppointmentProcess);
        }
    }

    public static void changeAssignedResource(List<ServiceAppointment> lstServiceAppointment){
        Set<Id> setWorkOrderIds = new Set<Id>();
        Set<Id> setTerminalIds = new Set<Id>();
        List<SerializedProduct> lstSerializedProducts = new List<SerializedProduct>();
        List<SerializedProduct> lstSerializedProductsUpdate = new List<SerializedProduct>();
        List<Terminal_ID__c> lstTerminalIds = new List<Terminal_ID__c>();

        Map<Id, List<Terminal_ID__c>> mapTerminalId = new Map<Id, List<Terminal_ID__c>>();
        Map<Id, SerializedProduct> mapSerializedProductByTerminalId = new Map<Id, SerializedProduct>();


        
        //get WorkOrder Ids
        for (ServiceAppointment appointment : lstServiceAppointment) {
            setWorkOrderIds.add(appointment.FSSK__FSK_Work_Order__c);
        }

        lstTerminalIds = [SELECT Id, Name, Work_Order_ID__c FROM Terminal_ID__c WHERE Work_Order_ID__c IN :setWorkOrderIds];
        System.debug('>>>>>>>>> lstTerminalIds ' + lstTerminalIds);

        //map Terminal Ids
        for(Terminal_ID__c terminalId : lstTerminalIds){
            List<Terminal_ID__c> lstMapTerminalId = new List<Terminal_ID__c>();

            if(mapTerminalId.containsKey(terminalId.Work_Order_ID__c)){
                lstMapTerminalId = mapTerminalId.get(terminalId.Work_Order_ID__c);
            }
            lstMapTerminalId.add(terminalId);

            mapTerminalId.put(terminalId.Work_Order_ID__c, lstMapTerminalId);
            setTerminalIds.add(terminalId.Id);
        }
        
        //get SerializedProducts by Terminal Id
        lstSerializedProducts = [SELECT Id, Name, Picked_Up__c, Terminal_ID_TID_Id__c FROM SerializedProduct WHERE Terminal_ID_TID_Id__c IN :setTerminalIds];
        System.debug('>>>>>>>>> lstSerializedProducts ' + lstSerializedProducts);

        for(SerializedProduct sp : lstSerializedProducts){
            mapSerializedProductByTerminalId.put(sp.Terminal_ID_TID_Id__c, sp);
        }

        for(ServiceAppointment sa : lstServiceAppointment){
            List<Terminal_ID__c> lstSATerminalIds = new List<Terminal_ID__c>();
            lstSATerminalIds = mapTerminalId.get(sa.FSSK__FSK_Work_Order__c);
            
            if(lstSATerminalIds.isEmpty()){ continue; }

            for(Terminal_ID__c terminalId : lstSATerminalIds){
                SerializedProduct sp = mapSerializedProductByTerminalId.get(terminalId.Id);

                if(sp != null && sa.FSSK__FSK_Assigned_Service_Resource__c != null){
                    sp.Picked_Up__c = false;
                    lstSerializedProductsUpdate.add(sp);
                }
            }
        }

        System.debug('>>>>>>>>> lstSerializedProductsUpdate ' + lstSerializedProductsUpdate);
        update lstSerializedProductsUpdate;
    }

    public static void checkCompletedInstalation(List<ServiceAppointment> lstServiceAppointment, Map<Id, ServiceAppointment> oldMap){
        List<ServiceAppointment> lstServiceAppointmentProcess = new List<ServiceAppointment>();
        for (ServiceAppointment appointment : lstServiceAppointment) {
            ServiceAppointment oldAppointment = oldMap.get(appointment.Id);
            
            if (appointment.Status != oldAppointment.Status
                && (appointment.Status == 'Completed'
                    || appointment.Status == 'Cannot Complete'
                    || appointment.Status == 'Canceled By Client'
                    || appointment.Status == 'None')) {
                lstServiceAppointmentProcess.add(appointment);
            }
        }

        if(!lstServiceAppointmentProcess.isEmpty()){
            // validate Collected / Replaced / Installed Devices
            // checkCompletedInstalation(lstServiceAppointmentProcess);
        }
    }


    public static void validateWorkDoneStatus(List<ServiceAppointment> lstServiceAppointment, Map<Id, ServiceAppointment> oldMap){
        List<ServiceAppointment> lstServiceAppointmentProcess = new List<ServiceAppointment>();
        for (ServiceAppointment appointment : lstServiceAppointment) {
            ServiceAppointment oldAppointment = oldMap.get(appointment.Id);
            
            if (appointment.Status != oldAppointment.Status
                && appointment.Status == 'Work Done') {
                lstServiceAppointmentProcess.add(appointment);
            }
        }

        if(!lstServiceAppointmentProcess.isEmpty()){
            validateWorkDoneStatus(lstServiceAppointmentProcess);
        }
    }


    public static void validateWorkDoneStatus(List<ServiceAppointment> lstServiceAppointment) {
        Set<Id> setWolis = new Set<Id>();
        
        // Collect Work Order Line Item IDs
        for (ServiceAppointment appointment : lstServiceAppointment) {
            if (appointment.Work_Order_Line_Item__c != null) {
                setWolis.add(appointment.Work_Order_Line_Item__c);
            }
        }
    
        // Query related ReturnOrderLineItems
        List<ReturnOrderLineItem> lstReturnOrderLineItem = [ 
            SELECT Id, Work_Order_Line_Item__c, Status_list__c 
            FROM ReturnOrderLineItem 
            WHERE Work_Order_Line_Item__c IN :setWolis
        ];
    
        // Map ReturnOrderLineItems by Work Order Line Item ID
        Map<Id, List<ReturnOrderLineItem>> mapReturnOrderLines = new Map<Id, List<ReturnOrderLineItem>>();
        
        for (ReturnOrderLineItem rol : lstReturnOrderLineItem) {
            if (!mapReturnOrderLines.containsKey(rol.Work_Order_Line_Item__c)) {
                mapReturnOrderLines.put(rol.Work_Order_Line_Item__c, new List<ReturnOrderLineItem>());
            }
            mapReturnOrderLines.get(rol.Work_Order_Line_Item__c).add(rol);
        }
    
        // Validate each ServiceAppointment
        for (ServiceAppointment appointment : lstServiceAppointment) {
            if (appointment.Work_Order_Line_Item__c != null && mapReturnOrderLines.containsKey(appointment.Work_Order_Line_Item__c)) {
                for (ReturnOrderLineItem rol : mapReturnOrderLines.get(appointment.Work_Order_Line_Item__c)) {
                    if (String.isBlank(rol.Status_list__c)) {
                        appointment.addError('Return Order Line Item has an empty status.');
                        continue;
                    }
                }
            }
        }
    }
}