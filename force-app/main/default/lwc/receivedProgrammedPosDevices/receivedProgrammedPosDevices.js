import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getReceivedProgrammedPOSDevices from '@salesforce/apex/ProgrammedPOSDevicesController.getReceivedProgrammedPOSDevices';
import returnDevicesToProgrammer from '@salesforce/apex/ProgrammedPOSDevicesController.returnDevicesToProgrammer';
import searchProgrammedPOSDevices from '@salesforce/apex/ProgrammedPOSDevicesController.searchProgrammedPOSDevices';

export default class ReceivedProgrammedPosDevices extends LightningElement {
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
            const result = await getReceivedProgrammedPOSDevices();
            this.devices = result.map(device => ({
                ...device,
                id: device.id,
                returnToProgrammer: device.isPickedUp ? false : device.returnToProgrammer,
                rowClass: device.isPickedUp ? 'slds-hint-parent slds-theme_shade' : ''
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
                viewType: 'received'
            });
            this.filteredDevices = result.map(device => ({
                ...device,
                id: device.id,
                returnToProgrammer: device.isPickedUp ? false : device.returnToProgrammer,
                rowClass: device.isPickedUp ? 'slds-hint-parent slds-theme_shade' : ''
            }));
        } catch (error) {
            this.showToast('Error', 'Error searching devices: ' + error.body.message, 'error');
        } finally {
            this.isLoading = false;
        }
    }

    handleReturnToProgrammerChange(event) {
        const deviceId = event.target.dataset.id;
        const isChecked = event.target.checked;
        
        this.filteredDevices = this.filteredDevices.map(device => {
            if (device.id === deviceId) {
                return { ...device, returnToProgrammer: isChecked };
            }
            return device;
        });

        this.devices = this.devices.map(device => {
            if (device.id === deviceId) {
                return { ...device, returnToProgrammer: isChecked };
            }
            return device;
        });
    }

    async handleReturnToProgrammer() {
        try {
            this.isLoading = true;
            
            // Get device IDs where returnToProgrammer checkbox is checked
            const returnDeviceIds = this.filteredDevices
                .filter(device => device.returnToProgrammer === true && !device.isPickedUp)
                .map(device => device.id);
            
            if (returnDeviceIds.length === 0) {
                this.showToast('Warning', 'Please check the "Return to Programmer" checkbox for devices to return', 'warning');
                return;
            }

            await returnDevicesToProgrammer({ deviceIds: returnDeviceIds });
            
            this.showToast('Success', 'Devices returned to programmer successfully', 'success');
            
            await this.loadData();
            
        } catch (error) {
            this.showToast('Error', 'Error returning devices to programmer: ' + error.body.message, 'error');
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

    get showNoDataMessage() {
        return !this.hasDevices && !this.isLoading;
    }

    get availableDevicesCount() {
        return this.filteredDevices.filter(device => !device.isPickedUp).length;
    }

    get pickedUpDevicesCount() {
        return this.filteredDevices.filter(device => device.isPickedUp).length;
    }

    get hasReturnDevices() {
        return this.filteredDevices.some(device => device.returnToProgrammer === true && !device.isPickedUp);
    }

    get disableReturnButton() {
        return !this.hasReturnDevices || this.isLoading;
    }
}