import { LightningElement, api, track } from "lwc";
import getRelatedAssets from "@salesforce/apex/DeviceController.getRelatedAssets";
import { FlowNavigationPauseEvent, FlowNavigationBackEvent  , FlowNavigationNextEvent } from "lightning/flowSupport";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class DeviceReplacementScreen extends LightningElement {
  handleRecordSelection(event) {
    event.stopPropagation();
    let dataRecieved = event.detail.data;
    let productId =
      dataRecieved.selectedId !== undefined ? dataRecieved.selectedId : null;
    let updatedItem = { id: dataRecieved.key, productId: productId };
    console.log(updatedItem);
    this.updateDataValues(updatedItem);
  }
  @track selectedRows;
  @track sessionData;
  @track editTableData = [];
  @track draftValues = [];

  _flowGUID;
  @api
  set flowGUID(value) {
    this._flowGUID = value;
  }
  get flowGUID() {
    return this._flowGUID;
  }
  @api
  get updatedAssets() {
    return this.editTableData.map((record) => record);
  }
  @api
  get recordsToUpdate() {
    return this.editTableData.map((record) => record);
  }
  @api
  get recordsToUpdate2() {
    return this.editTableData.map((record) => record);
  }
  @api
  get updatedRecords() {
    this.putSessionData();
    return this.editTableData.map((record) => record);
  }
  putSessionData() {
    this.sessionData = {
      selectedRowIds: this.editTableData.map((record) => record.id),
      records: this.editTableData.map((record) => record)
    };
    sessionStorage.setItem(this._flowGUID, JSON.stringify(this.sessionData));
  }
  get getSelectedRowIds() {
    return this.editTableData.map((record) => record.id) || [];
  }
  @track selected = [];
  connectedCallback() {
    this.selectedRowIds = new Set();
  }

  editTableColumns = [
    {
      label: "Terminal Id",
      type: "text",
      fieldName: "terminalIdName",
      editable: true
    },
    {
      label: "Product",
      fieldName: "productId",
      type: "lookup",
      typeAttributes: {
        placeholder: "Product Name",
        uniqueId: { fieldName: "id" }, //pass Id of current record to lookup for context
        object: "Product2",
        icon: "standard:product",
        label: "Product",
        displayFields: "Name,Id",
        displayFormat: "Name",
        filters: "",
        valueId: { fieldName: "productId" } // binding Parent Id of current item in row to autopopulate value on load.
      }
    }
  ];

  loadSessionData() {
    const data = sessionStorage.getItem(this._flowGUID);
    if (!data) return;
    const parsedData = JSON.parse(data);
    this.sessionData = parsedData;
    this.selectedRowIds = new Set(parsedData.selectedRowIds);
    this.editTableData = parsedData.records;
    this.selected = Array.from(this.selectedRowIds);
  }
  dataLoaded = false;
  renderedCallback() {
    if (this.flowGUID && this.accountIds && !this.dataLoaded) {
      this.getRecords()
        .then(() => {
          this.dataLoaded = true;
        })
        .catch(() => {
          this.dataLoaded = false;
        });
    }
  }
  /**
   * get all assets
   * @param {String} accountId
   */
  async getRecords() {
    try {
      this.showSpinner = true;
      const response = await getRelatedAssets({ accountIds: this.accountIds });
      console.log(JSON.parse(JSON.stringify(response)));
      this.records = response.map((record) => record);
      this.loadSessionData();
    } catch (error) {
      console.warn(error);
    } finally {
      this.showSpinner = false;
    }
  }
  showSpinner = false;
  @track records = [];
  _accountId;
  @api
  set accountId(value) {
    console.log("first", value);
    this._accountId = value;
  }
  get accountId() {
    return this._accountId;
  }
  _accountIds;
  @api
  set accountIds(value) {
    console.log("second", value);
    this._accountIds = value;
  }
  get accountIds() {
    return this._accountIds;
  }
  @track selectedRowIds = new Set();
  columns = [
    {
      type: "text",
      label: "Device Name",
      fieldName: "name"
    },
    {
      type: "text",
      label: "Serial Number",
      fieldName: "serialNumber"
    },
    {
      type: "text",
      label: "Terminal ID",
      fieldName: "terminalIdName"
    }
  ];

  get recordsAvailable() {
    return Array.isArray(this.records) && this.records.length > 0;
  }
  handleRowSelection(event) {
    const selectedRows = event.detail.selectedRows;
    let tempSet = new Set(selectedRows.map((row) => row.id)); //current rows selected
    let idsToRemove = new Set();
    for (const rowId of this.selectedRowIds) {
      if (!tempSet.has(rowId)) {
        this.selectedRowIds.delete(rowId); //remove the row from the selected set
        idsToRemove.add(rowId); //newly removed rows
      }
    }
    //check if any rows are de-selected
    console.info("Selected", JSON.parse(JSON.stringify(selectedRows)));
    const rows = selectedRows.filter((row) => {
      return !this.selectedRowIds.has(row.id);
    });
    let newAdded = new Set();
    console.info("Added", rows);
    for (const row of rows) {
      this.selectedRowIds.add(row.id);
      newAdded.add(row.id);
    }
    console.info("Added new", newAdded);
    const data = this.records
      .filter((row) => this.selectedRowIds.has(row.id))
      .map((row) => row);
    console.log("concatenated", data);
    if (data.length > 0) {
      this.editTableData = [...data];
    } else {
      this.editTableData = [];
    }

    //populate row in the  right table
  }

  handleCancel() {
    this.draftValues = [];
  }
  updateDataValues(updateItem) {
    let copyData = JSON.parse(JSON.stringify(this.editTableData));

    copyData.forEach((item) => {
      if (item.id === updateItem.id) {
        // eslint-disable-next-line guard-for-in
        for (let field in updateItem) {
          item[field] = updateItem[field];
        }
      }
    });

    //write changes back to original data
    this.editTableData = [...copyData];
  }
  handleSave(event) {
    const data = {};
    // Convert datatable draft values into record objects
    for (const draft of event.detail.draftValues) {
      data[draft.id] = draft;
    }
    console.info(data, "first");
    for (let index = 0; index < this.editTableData.length; index++) {
      const rowElement = this.editTableData[index];
      const dataElement = data[rowElement.id];
      if (!dataElement) continue;
      console.info(dataElement, "data element");
      console.info(rowElement, "row element");
      // editTable[index].terminalIdName = dataElement.terminalIdName;
      this.updateDataValues({
        id: rowElement.id,
        terminalIdName: dataElement.terminalIdName
      });
    }

    console.log(data);
    // Clear all datatable draft values
    this.draftValues = [];
  }

  get canShowEditTable() {
    return this.editTableData && this.editTableData.length > 0;
  }

  handleNextButton() {
    if (this.validateRequiredFields()) {
      const navigateNextEvent = new FlowNavigationNextEvent();
      this.dispatchEvent(navigateNextEvent);
    }
  }

  showToast(title, message, variant) {
    const event = new ShowToastEvent({
        title: title,
        message: message,
        variant: variant
    });
    this.dispatchEvent(event);
  }

  
  handlePreviousButton() {
    const navigatePreviousEvent = new FlowNavigationBackEvent();
    this.dispatchEvent(navigatePreviousEvent);
  }

  handleSaveButton() {
    const navigateSaveEvent = new FlowNavigationPauseEvent();
    this.dispatchEvent(navigateSaveEvent);
  }


  validateRequiredFields() {
    if(!this.editTableData || this.editTableData.length === 0){
      this.showToast('Error', 'You must select a device', 'error');
      return false;
    }

    for (let index = 0; index < this.editTableData.length; index++) {
      const rowElement = JSON.parse(JSON.stringify(this.editTableData[index]));

      if (rowElement.terminalIdName == undefined || rowElement.terminalIdName == '' || !rowElement.terminalIdName || rowElement.productId == undefined || rowElement.productId == '' || !rowElement.productId) {
        this.showToast('Error', 'Missing Terminal or Product Id', 'error');
        loadSessionData();
        return false;
      } 
    }
    return true;
  }
}