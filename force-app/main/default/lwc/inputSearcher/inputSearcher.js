import { LightningElement,api,track } from 'lwc';
const NO_RECORDS_MESSAGE = "No Records Found";
import findRecords from "@salesforce/apex/DeviceController.findRecords";

export default class InputSearcher extends LightningElement {
    @api lookupFilter = null;
    @track timerId;
  
    @track recordsList;
    @track searchKey = "";
    @track selectedRecord;
    @api queryFields = ["Id", "Name"];
    @api
    get selectedRecordName() {
      return this.selectedRecordNameTracked;
    }
    set selectedRecordName(value) {
      this.selectedRecordNameTracked = value;
    }
    @track selectedRecordNameTracked;
    @api objectApiName;
    @api iconName;
    @api lookupLabel;
  
    @api
    required = false;
  
    renderedCallback() {
      this.manageInputRequired(this.required);
    }
    @track isLoading;
    @track message;
    _apiRecordsList;
    manageInputRequired(required) {
        const inputElement = this.template.querySelector("input");
        if (inputElement) {
          if (required) {
            inputElement.setAttribute("required", "");
          } else {
            inputElement.removeAttribute("required");
          }
        }
      }
        /**
   * focus out close
   */
  onFocusOut() {
    setTimeout(() => {
      this.searchKey = "";
      this.recordsList = null;
    }, 200);
  }
  @api
  get apiRecordsList() {
    return this._apiRecordsList;
  }
  set apiRecordsList(value) {
    if (value) {
      this._apiRecordsList = value;
    }
  }
    /**
   * search term selection event
   * @param {Event} event
   */

    onRecordSelection(event) {
        const index = event.currentTarget.dataset.index;
        this.selectedRecord = this.recordsList[index];
        this.selectedRecordNameTracked = this.selectedRecord.name;
        this.searchKey = "";
        this.onSelectedRecordUpdate();
      }
        /**
   * listens for key changes (character)
   * @param {Event} event
   * @returns
   */
  async handleKeyChange(event) {
    const searchKey = event.target.value;
    this.searchKey = searchKey;
    await this.setAsyncTimeout(async () => {
      await this.getLookupResult(this.queryFields.join(","), this.lookupFilter);
    }, 500);
  }
    /**
   * search object by name and filter
   * @param {Array<String>} fields
   * @param {String} filter
   * @returns
   */
    async getLookupResult(fields, filter = null) {
        try {
          this.isLoading = true;
          const searchResults = await findRecords({
            value: this.searchKey,
            objectName: this.objectApiName
          });
          if (searchResults && searchResults.length === 0) {
            this.recordsList = [];
            this.message = NO_RECORDS_MESSAGE;
            return;
          }
          this.message = "";
          // parse details
          this.recordsList = searchResults.map((result) => ({
            id: result.Id,
            name: result.Name
          }));
          console.log(this.recordsList, 'breadcrumbs');
        }catch (error) {
            this.recordsList = null;
            console.error(error);
          } finally {
            this.isLoading = false;
          }
    }
      /**
   * fire event with the selected record
   */
  onSelectedRecordUpdate() {
    this.dispatchEvent(
      new CustomEvent("recordselection", {
        detail: {
          record: this.selectedRecord
        }
      })
    );
  }
    /**
   * debouncing function
   */
    setAsyncTimeout(cb, timeout = 0) {
        return new Promise((resolve) => {
          clearTimeout(this.timerId);
          this.timerId = setTimeout(() => {
            cb();
            resolve();
          }, timeout);
        });
      }  
      @api
      removeRecordOnLookup() {
        this.searchKey = "";
        this.selectedRecordNameTracked = "";
        this.selectedRecord = {};
        this.onSelectedRecordUpdate();
      } 
}