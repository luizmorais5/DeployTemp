import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
// Import Apex methods - placeholder imports that will need actual implementation
import getPOSDevicesForShipment from '@salesforce/apex/ShippedPOSDevicesController.getPOSDevicesForShipment';
import getShippedPOSDevices from '@salesforce/apex/ShippedPOSDevicesController.getShippedPOSDevices';
import getReceivedShippedPOSDevices from '@salesforce/apex/ShippedPOSDevicesController.getReceivedShippedPOSDevices';
import confirmShipment from '@salesforce/apex/ShippedPOSDevicesController.confirmShipment';
import confirmReceipt from '@salesforce/apex/ShippedPOSDevicesController.confirmReceipt';
import searchPOSDevices from '@salesforce/apex/ShippedPOSDevicesController.searchPOSDevices';

export default class ShippedPOSDevices extends LightningElement {
    // Scenario 1: Shipping Mode Selection
    @track selectedShippingMode = '';
    
    // Scenario 2: Hub and Territory Selection
    @track selectedHub = '';
    @track selectedTerritory = '';
    
    // Device View Management
    @track activeDeviceView = 'devices-for-shipment';
    @track devices = [];
    @track filteredDevices = [];
    @track searchTerm = '';
    @track isLoading = false;
    @track error;

    // Scenario 1: Shipping mode options
    get shippingModeOptions() {
        return [
            { label: 'Ship to Hub', value: 'ship-to-hub' },
            { label: 'Ship to Territory', value: 'ship-to-territory' }
        ];
    }

    // Scenario 2: Hub options (St. James, Manchester)
    get hubOptions() {
        return [
            { label: 'St. James', value: 'St. James' },
            { label: 'Manchester', value: 'Manchester' }
        ];
    }

    // Territory options (all territories except Jamaica and its child territories)
    get territoryOptions() {
        return [
            { label: 'Kingston', value: 'Kingston' },
            { label: 'Spanish Town', value: 'Spanish Town' },
            { label: 'Montego Bay', value: 'Montego Bay' },
            { label: 'Mandeville', value: 'Mandeville' },
            { label: 'Ocho Rios', value: 'Ocho Rios' }
        ];
    }

    // Device view options based on scenarios 3, 7, 9
    get deviceViewOptions() {
        return [
            { label: 'POS Devices for Shipment', value: 'devices-for-shipment' },
            { label: 'Shipped POS Devices', value: 'shipped-devices' },
            { label: 'Received Shipped POS Devices', value: 'received-shipped-devices' }
        ];
    }

    // Reship destination options for scenario 9
    get reshipDestinationOptions() {
        return [
            { label: 'St. James Hub', value: 'st-james-hub' },
            { label: 'Manchester Hub', value: 'manchester-hub' },
            { label: 'Return to Logistics', value: 'return-logistics' }
        ];
    }

    // Computed properties for shipping mode
    get isShipToHubMode() {
        return this.selectedShippingMode === 'ship-to-hub';
    }

    get isShipToTerritoryMode() {
        return this.selectedShippingMode === 'ship-to-territory';
    }

    // Show device views only when a shipping destination is selected
    get showDeviceViews() {
        return (this.isShipToHubMode && this.selectedHub) || 
               (this.isShipToTerritoryMode && this.selectedTerritory);
    }

    // Column visibility based on current view
    get showShippedColumn() {
        return this.activeDeviceView === 'devices-for-shipment';
    }

    get showReceivedColumn() {
        return this.activeDeviceView === 'shipped-devices';
    }

    get showReshipColumn() {
        return this.activeDeviceView === 'received-shipped-devices';
    }

    get showReshipDestinationColumn() {
        return this.activeDeviceView === 'received-shipped-devices';
    }

    get showConfirmButton() {
        return this.activeDeviceView === 'devices-for-shipment' || 
               this.activeDeviceView === 'shipped-devices';
    }

    get confirmButtonLabel() {
        switch (this.activeDeviceView) {
            case 'devices-for-shipment':
                return 'Confirm Shipment';
            case 'shipped-devices':
                return 'Confirm Receipt';
            default:
                return 'Confirm';
        }
    }

    get hasDevices() {
        return this.filteredDevices && this.filteredDevices.length > 0;
    }

    get hasSelectedDevices() {
        if (this.activeDeviceView === 'devices-for-shipment') {
            return this.filteredDevices.some(device => device.shipped === true);
        } else if (this.activeDeviceView === 'shipped-devices') {
            return this.filteredDevices.some(device => device.received === true);
        }
        return false;
    }

    get disableConfirmButton() {
        return !this.hasSelectedDevices || this.isLoading;
    }

    get showNoDataMessage() {
        return !this.isLoading && !this.error && !this.hasDevices && this.showDeviceViews;
    }

    get noDataMessage() {
        switch (this.activeDeviceView) {
            case 'devices-for-shipment':
                return 'No POS devices available for shipment';
            case 'shipped-devices':
                return 'No shipped POS devices found';
            case 'received-shipped-devices':
                return 'No received shipped POS devices found';
            default:
                return 'No devices found';
        }
    }

    get noDataDescription() {
        switch (this.activeDeviceView) {
            case 'devices-for-shipment':
                return 'There are currently no programmed POS devices available for shipment to the selected destination.';
            case 'shipped-devices':
                return 'There are currently no shipped POS devices waiting to be received.';
            case 'received-shipped-devices':
                return 'There are currently no received shipped POS devices to display.';
            default:
                return 'Please select a shipping destination to view available devices.';
        }
    }

    // Scenario 1: Handle shipping mode change
    handleShippingModeChange(event) {
        this.selectedShippingMode = event.target.value;
        this.selectedHub = '';
        this.selectedTerritory = '';
        this.resetDeviceData();
    }

    // Scenario 2: Handle hub selection change
    handleHubChange(event) {
        this.selectedHub = event.target.value;
        this.resetDeviceData();
        this.loadDeviceData();
    }

    // Handle territory selection change
    handleTerritoryChange(event) {
        this.selectedTerritory = event.target.value;
        this.resetDeviceData();
        this.loadDeviceData();
    }

    // Handle device view change (scenarios 3, 7, 9)
    handleDeviceViewChange(event) {
        this.activeDeviceView = event.target.value;
        this.resetDeviceData();
        this.loadDeviceData();
    }

    // Scenario 3: Load device data based on current view and destination
    async loadDeviceData() {
        if (!this.showDeviceViews) return;

        try {
            this.isLoading = true;
            let result;
            const destination = this.selectedHub || this.selectedTerritory;
            const destinationType = this.selectedHub ? 'hub' : 'territory';

            switch (this.activeDeviceView) {
                case 'devices-for-shipment':
                    result = await getPOSDevicesForShipment({ 
                        destination: destination,
                        destinationType: destinationType 
                    });
                    break;
                case 'shipped-devices':
                    result = await getShippedPOSDevices({ 
                        destination: destination,
                        destinationType: destinationType 
                    });
                    break;
                case 'received-shipped-devices':
                    result = await getReceivedShippedPOSDevices({ 
                        destination: destination,
                        destinationType: destinationType 
                    });
                    break;
                default:
                    result = [];
            }

            this.devices = result.map(device => ({
                ...device,
                id: device.id,
                shipped: this.activeDeviceView === 'devices-for-shipment' ? true : (device.shipped || false), // Scenario 2: checked by default for territory shipment
                received: this.activeDeviceView === 'shipped-devices' ? true : (device.received || false), // Scenario 6: checked by default for shipped devices
                reship: device.reship || false,
                reshipDestination: device.reshipDestination || '',
                dateSent: device.dateSent,
                dateReceived: device.dateReceived,
                serviceTerritory: device.serviceTerritory,
                destinationType: this.isShipToTerritoryMode ? 'territory' : 'hub',
                rowClass: ''
            }));

            this.filteredDevices = [...this.devices];
            this.error = undefined;
        } catch (error) {
            console.log('Error loading device data:', error);
            this.error = error;
            this.devices = [];
            this.filteredDevices = [];
        } finally {
            this.isLoading = false;
        }
    }

    resetDeviceData() {
        this.devices = [];
        this.filteredDevices = [];
        this.searchTerm = '';
        this.error = undefined;
    }

    // Scenario 4: Handle search functionality
    handleSearch(event) {
        this.searchTerm = event.target.value;
        this.performSearch();
    }

    async performSearch() {
        if (!this.searchTerm) {
            this.filteredDevices = [...this.devices];
            return;
        }

        try {
            this.isLoading = true;
            const destination = this.selectedHub || this.selectedTerritory;
            const destinationType = this.selectedHub ? 'hub' : 'territory';

            const result = await searchPOSDevices({
                searchTerm: this.searchTerm,
                viewType: this.activeDeviceView,
                destination: destination,
                destinationType: destinationType
            });

            this.filteredDevices = result.map(device => ({
                ...device,
                id: device.id,
                shipped: device.shipped || true,
                received: device.received || false,
                reship: device.reship || false,
                reshipDestination: device.reshipDestination || '',
                rowClass: ''
            }));
        } catch (error) {
            this.showToast('Error', 'Error searching devices: ' + error.body.message, 'error');
        } finally {
            this.isLoading = false;
        }
    }

    // Scenario 3: Handle shipped checkbox change
    handleShippedChange(event) {
        const deviceId = event.target.dataset.id;
        const isChecked = event.target.checked;
        this.updateDeviceProperty(deviceId, 'shipped', isChecked);
    }

    // Scenario 7: Handle received checkbox change
    handleReceivedChange(event) {
        const deviceId = event.target.dataset.id;
        const isChecked = event.target.checked;
        this.updateDeviceProperty(deviceId, 'received', isChecked);
    }

    // Scenario 9: Handle reship checkbox change
    handleReshipChange(event) {
        const deviceId = event.target.dataset.id;
        const isChecked = event.target.checked;
        this.updateDeviceProperty(deviceId, 'reship', isChecked);
    }

    // Scenario 9: Handle reship destination change
    handleReshipDestinationChange(event) {
        const deviceId = event.target.dataset.id;
        const selectedValue = event.target.value;
        this.updateDeviceProperty(deviceId, 'reshipDestination', selectedValue);
    }

    updateDeviceProperty(deviceId, propertyName, value) {
        this.filteredDevices = this.filteredDevices.map(device => {
            if (device.id === deviceId) {
                return { ...device, [propertyName]: value };
            }
            return device;
        });

        this.devices = this.devices.map(device => {
            if (device.id === deviceId) {
                return { ...device, [propertyName]: value };
            }
            return device;
        });
    }

    // Scenario 5 & 8: Handle confirmation actions
    async handleConfirmAction() {
        try {
            this.isLoading = true;

            if (this.activeDeviceView === 'devices-for-shipment') {
                await this.handleConfirmShipment();
            } else if (this.activeDeviceView === 'shipped-devices') {
                await this.handleConfirmReceipt();
            }

        } catch (error) {
            console.log('error', error);
            this.showToast('Error', 'Error processing confirmation: ' + error.body.message, 'error');
        } finally {
            this.isLoading = false;
        }
    }

    // Scenario 5: Confirm shipment of POS devices
    async handleConfirmShipment() {
        const shippedDeviceIds = this.filteredDevices
            .filter(device => device.shipped === true)
            .map(device => device.id);

        if (shippedDeviceIds.length === 0) {
            this.showToast('Warning', 'Please select devices to ship by checking the "Shipped" checkbox', 'warning');
            return;
        }

        const destination = this.selectedHub || this.selectedTerritory;
        const destinationType = this.selectedHub ? 'hub' : 'territory';

        await confirmShipment({ 
            deviceIds: shippedDeviceIds,
            destination: destination,
            destinationType: destinationType
        });

        this.showToast('Success', 'Devices shipped successfully', 'success');
        await this.loadDeviceData();
    }

    // Scenario 8: Confirm receipt of shipped devices
    async handleConfirmReceipt() {
        const receivedDeviceIds = this.filteredDevices
            .filter(device => device.received === true)
            .map(device => device.id);

        if (receivedDeviceIds.length === 0) {
            this.showToast('Warning', 'Please select devices to confirm receipt by checking the "Received" checkbox', 'warning');
            return;
        }

        const destination = this.selectedHub || this.selectedTerritory;
        const destinationType = this.selectedHub ? 'hub' : 'territory';

        await confirmReceipt({ 
            deviceIds: receivedDeviceIds,
            destination: destination,
            destinationType: destinationType
        });

        this.showToast('Success', 'Device receipt confirmed successfully', 'success');
        await this.loadDeviceData();
    }

    showToast(title, message, variant) {
        const toast = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(toast);
    }
}