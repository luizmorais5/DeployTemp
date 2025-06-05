import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getProgrammedPOSDevices from '@salesforce/apex/ProgrammedPOSDevicesController.getProgrammedPOSDevices';
import confirmReceiptOfDevices from '@salesforce/apex/ProgrammedPOSDevicesController.confirmReceiptOfDevices';
import searchProgrammedPOSDevices from '@salesforce/apex/ProgrammedPOSDevicesController.searchProgrammedPOSDevices';

export default class ProgrammedPosDevices extends LightningElement {
    @track devices = [];
    @track filteredDevices = [];
    @track searchTerm = '';
    @track isLoading = false;
    @track error;

    connectedCallback() {
        this.loadData();
    }

    async loadData() {
        try {
            this.isLoading = true;
            const result = await getProgrammedPOSDevices();
            this.devices = result.map(device => ({
                ...device,
                id: device.id,
                rowClass: ''
            }));
            this.filteredDevices = [...this.devices];
            this.error = undefined;
        } catch (error) {
            console.log('Error loading data:', error);
            this.error = error;
            this.devices = [];
            this.filteredDevices = [];
        } finally {
            this.isLoading = false;
        }
    }

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
            const result = await searchProgrammedPOSDevices({
                searchTerm: this.searchTerm,
                viewType: 'programmed'
            });
            this.filteredDevices = result.map(device => ({
                ...device,
                id: device.id,
                rowClass: ''
            }));
        } catch (error) {
            this.showToast('Error', 'Error searching devices: ' + error.body.message, 'error');
        } finally {
            this.isLoading = false;
        }
    }

    handleReceivedChange(event) {
        const deviceId = event.target.dataset.id;
        const isChecked = event.target.checked;
        
        this.filteredDevices = this.filteredDevices.map(device => {
            if (device.id === deviceId) {
                return { ...device, received: isChecked };
            }
            return device;
        });

        this.devices = this.devices.map(device => {
            if (device.id === deviceId) {
                return { ...device, received: isChecked };
            }
            return device;
        });
    }

    async handleConfirmReceipt() {
        try {
            this.isLoading = true;
            
            // Get device IDs where received checkbox is checked
            const receivedDeviceIds = this.filteredDevices
                .filter(device => device.received === true)
                .map(device => device.id);
            
            if (receivedDeviceIds.length === 0) {
                this.showToast('Warning', 'Please check the "Received" checkbox for devices to confirm receipt', 'warning');
                return;
            }

            await confirmReceiptOfDevices({ deviceIds: receivedDeviceIds });
            
            this.showToast('Success', 'Devices confirmed successfully', 'success');
            
            await this.loadData();
            
        } catch (error) {
            console.log('error', error);
            this.showToast('Error', 'Error confirming devices: ' + error.body.message, 'error');
        } finally {
            this.isLoading = false;
        }
    }

    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(evt);
    }

    get hasDevices() {
        return this.filteredDevices && this.filteredDevices.length > 0;
    }

    get hasReceivedDevices() {
        return this.filteredDevices.some(device => device.received === true);
    }

    get showNoDataMessage() {
        return !this.hasDevices && !this.isLoading;
    }

    get disableConfirmButton() {
        return !this.hasReceivedDevices || this.isLoading;
    }
}