import { LightningElement, track } from 'lwc';
import hasDualProgrammerLogisticianRole from '@salesforce/apex/ProgrammedPOSDevicesController.hasDualProgrammerLogisticianRole';

export default class PosDevicesManager extends LightningElement {
    @track activeTab = 'programmed';
    @track isDualRole = false;
    @track isLoading = true;

    connectedCallback() {
        this.checkDualRole();
    }

    async checkDualRole() {
        try {
            this.isDualRole = await hasDualProgrammerLogisticianRole();
        } catch (error) {
            console.error('Error checking dual role:', error);
            this.isDualRole = false;
        } finally {
            this.isLoading = false;
        }
    }

    get isProgrammedTabActive() {
        return this.activeTab === 'programmed';
    }

    get isReceivedTabActive() {
        return this.activeTab === 'received';
    }

    handleTabChange(event) {
        this.activeTab = event.target.value;
    }

    get tabOptions() {
        return [
            { label: 'Devices to be received', value: 'programmed' },
            { label: 'Received Devices', value: 'received' }
        ];
    }

    // Scenario 2: Hide views for dual-role users
    get shouldShowViews() {
        return !this.isDualRole && !this.isLoading;
    }

    get shouldShowDualRoleMessage() {
        return this.isDualRole && !this.isLoading;
    }
}