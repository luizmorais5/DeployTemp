import { LightningElement, api, track, wire } from 'lwc';

export default class Bright extends LightningElement {
    @api label = 'Search Contacts';
    @track searchTerm = '';
    @track searchResults = [];
    @track showDropdown = false;

    handleSearch(event) {
        this.searchTerm = event.target.value;
        this.searchResults = [{
            Name: 'Remario',
            Id: '1'
        }];
        this.showDropdown = true;
    }

    handleSelect(event) {
        const selectedContactId = event.currentTarget.dataset.id;
        const selectedContactName = event.currentTarget.dataset.name;

        const selectedEvent = new CustomEvent('selected', {
            detail: {
                recordId: selectedContactId,
                recordName: selectedContactName
            }
        });

        this.dispatchEvent(selectedEvent);

        this.searchResults = [];
        this.showDropdown = false;
    }
}