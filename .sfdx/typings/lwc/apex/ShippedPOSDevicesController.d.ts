declare module "@salesforce/apex/ShippedPOSDevicesController.getPOSDevicesForShipment" {
  export default function getPOSDevicesForShipment(param: {destination: any, destinationType: any}): Promise<any>;
}
declare module "@salesforce/apex/ShippedPOSDevicesController.getShippedPOSDevices" {
  export default function getShippedPOSDevices(param: {destination: any, destinationType: any}): Promise<any>;
}
declare module "@salesforce/apex/ShippedPOSDevicesController.getReceivedShippedPOSDevices" {
  export default function getReceivedShippedPOSDevices(param: {destination: any, destinationType: any}): Promise<any>;
}
declare module "@salesforce/apex/ShippedPOSDevicesController.searchPOSDevices" {
  export default function searchPOSDevices(param: {searchTerm: any, viewType: any, destination: any, destinationType: any}): Promise<any>;
}
declare module "@salesforce/apex/ShippedPOSDevicesController.confirmShipment" {
  export default function confirmShipment(param: {deviceIds: any, destination: any, destinationType: any}): Promise<any>;
}
declare module "@salesforce/apex/ShippedPOSDevicesController.confirmReceipt" {
  export default function confirmReceipt(param: {deviceIds: any, destination: any, destinationType: any}): Promise<any>;
}
