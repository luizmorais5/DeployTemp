import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getReturnedPOSDevices from '@salesforce/apex/ReturnedPOSDevicesController.getReturnedPOSDevices';
import getAcceptedReturnedPOSDevices from '@salesforce/apex/ReturnedPOSDevicesController.getAcceptedReturnedPOSDevices';
import confirmAcceptanceOfDevices from '@salesforce/apex/ReturnedPOSDevicesController.confirmAcceptanceOfDevices';
import searchReturnedPOSDevices from '@salesforce/apex/ReturnedPOSDevicesController.searchReturnedPOSDevices';

export default class PosDevicesReturned extends LightningElement {
    @track activeTab = 'returned';
    @track devices = [];
    @track filteredDevices = [];
    @track searchTerm = '';
    @track isLoading = false;
    @track error;

    get isReturnedTabActive() {
        return this.activeTab === 'returned';
    }

    get isAcceptedTabActive() {
        return this.activeTab === 'accepted';
    }

    get tabOptions() {
        return [
            { label: 'Returned POS Devices', value: 'returned' },
            { label: 'Accepted Returned POS Devices', value: 'accepted' }
        ];
    }

    connectedCallback() {
        this.loadData();
    }

    handleTabChange(event) {
        this.activeTab = event.target.value;
        this.resetDevicesData();
        this.loadData();
    }

    async loadData() {
        try {
            this.isLoading = true;
            
            let result;
            if (this.activeTab === 'returned') {
                result = await getReturnedPOSDevices();
            } else {
                result = await getAcceptedReturnedPOSDevices();
            }
            
            this.devices = result.map(device => ({
                ...device,
                id: device.id,
                accepted: device.accepted || false,
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

    async refreshDeviceData() {
        await this.loadData();
    }

    resetDevicesData() {
        this.devices = [];
        this.filteredDevices = [];
        this.searchTerm = '';
        this.error = undefined;
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
            const result = await searchReturnedPOSDevices({
                searchTerm: this.searchTerm,
                viewType: this.activeTab
            });
            this.filteredDevices = result.map(device => ({
                ...device,
                id: device.id,
                accepted: device.accepted || false,
                rowClass: ''
            }));
        } catch (error) {
            this.showToast('Error', 'Error searching devices: ' + error.body.message, 'error');
        } finally {
            this.isLoading = false;
        }
    }

    handleAcceptedChange(event) {
        const deviceId = event.target.dataset.id;
        const isChecked = event.target.checked;
        
        this.filteredDevices = this.filteredDevices.map(device => {
            if (device.id === deviceId) {
                return { ...device, accepted: isChecked };
            }
            return device;
        });

        this.devices = this.devices.map(device => {
            if (device.id === deviceId) {
                return { ...device, accepted: isChecked };
            }
            return device;
        });
    }

    async handleConfirmAcceptance() {
        try {
            this.isLoading = true;
            
            // Get device IDs where accepted checkbox is checked
            const acceptedDeviceIds = this.filteredDevices
                .filter(device => device.accepted === true)
                .map(device => device.id);
            
            if (acceptedDeviceIds.length === 0) {
                this.showToast('Warning', 'Please check the "Accepted" checkbox for devices to confirm acceptance', 'warning');
                return;
            }

            await confirmAcceptanceOfDevices({ deviceIds: acceptedDeviceIds });
            
            this.showToast('Success', 'Devices accepted successfully', 'success');
            
            await this.loadData();
            
        } catch (error) {
            console.log('error', error);
            this.showToast('Error', 'Error confirming device acceptance: ' + error.body.message, 'error');
        } finally {
            this.isLoading = false;
        }
    }

    showToast(title, message, variant) {
        const toast = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(toast);
    }

    get hasDevices() {
        return this.filteredDevices && this.filteredDevices.length > 0;
    }

    get hasAcceptedDevices() {
        return this.filteredDevices.some(device => device.accepted === true);
    }

    get disableConfirmButton() {
        return !this.hasAcceptedDevices || this.isLoading || this.activeTab !== 'returned';
    }

    get showNoDataMessage() {
        return !this.isLoading && !this.error && !this.hasDevices;
    }

    get noDataMessage() {
        return this.activeTab === 'returned' 
            ? 'No returned POS devices found'
            : 'No accepted returned POS devices found';
    }

    get noDataDescription() {
        return this.activeTab === 'returned'
            ? 'There are currently no returned POS devices available for acceptance confirmation.'
            : 'There are currently no accepted returned POS devices to display.';
    }

    get showAcceptedColumn() {
        return this.activeTab === 'returned';
    }

    get confirmButtonLabel() {
        return 'Confirm';
    }
}