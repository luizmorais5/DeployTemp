import { LightningElement, track, api, wire } from "lwc";
import getRelatedAssets from "@salesforce/apex/DeviceController.getRelatedAssets";
import getReturnOrderLineItems from "@salesforce/apex/DeviceController.getReturnOrderLineItems";
import { getPicklistValues, getObjectInfo } from "lightning/uiObjectInfoApi";
import ReturnOrderLineItem from "@salesforce/schema/ReturnOrderLineItem";
import STATUS_FIELD from "@salesforce/schema/ReturnOrderLineItem.Status_list__c";
import ID_FIELD from "@salesforce/schema/ReturnOrderLineItem.Id";
import { updateRecord } from "lightning/uiRecordApi";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

export default class DeviceReplacementMobile extends LightningElement {
  _recordsUpdatable = false;
  _recordId;
  @api
  set recordId(value) {
    this._recordId = value;
    this.getRecords(value)
      .then(() => {})
      .catch(() => {});
  }
  get recordId() {
    return this._recordId;
  }
  @track columns = [
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
      label: "Sim Card 1",
      fieldName: "simCard1Name"
    },
    {
      type: "text",
      label: "Sim Card 2",
      fieldName: "simCard2Name"
    }
  ];
  @wire(getObjectInfo, { objectApiName: ReturnOrderLineItem })
  objectInfo;
  @wire(getPicklistValues, {
    recordTypeId: "$objectInfo.data.defaultRecordTypeId",
    fieldApiName: STATUS_FIELD
  })
  wiredStatuses({ data, error }) {
    if (error) {
      this.statuses = [];
    } else if (data) {
      this.statuses = data.values.map((record) => ({
        label: record.label,
        value: record.value,
        text: record.value
      }));
      this.columns.push({
        label: "Type",
        type: "picklist",
        fieldName: "type",
        typeAttributes: {
          label: "",
          value: { fieldName: "status" },
          context: { fieldName: "returnLineItemId" },
          options: this.statuses
        }
      });
      console.log("Statuses", JSON.parse(JSON.stringify(this.statuses)));
    }
  }

  @track statuses = [];

  @api
  get updatedRecords() {
    this.putSessionData();
    console.info(
      "Updated records",
      JSON.parse(JSON.stringify(this.records.map((record) => record)))
    );
    return this.records.map((record) => record);
  }
  putSessionData() {
    sessionStorage.setItem("data", JSON.stringify(this.records));
  }
  @track showSpinner = false;
  @track records = [];
  _accountId;
  @api
  set accountId(value) {
    this._accountId = value;
    // this.getRecords(value)
    //   .then(() => {})
    //   .catch(() => {});
  }
  get accountId() {
    return this._accountId;
  }
  /**
   * get all assets
   * @param {String} accountId
   */
  async getRecords(recordId) {
    try {
      this.showSpinner = true;
      const data = this.loadSessionData();
      if (data && data.length > 0) {
        console.info('cached records', data);
        this.records = data.map((record) => record);
        return;
      }
      this.records = [];
      const response = await getReturnOrderLineItems({ recordIds: [recordId] });
      for (const returnLineItem of response) {
        this.records.push({
          returnLineItemId: returnLineItem.id,
          status: returnLineItem?.status,
          ...returnLineItem.asset
        });
      }
    } catch (error) {
      console.warn(error);
    } finally {
      this.showSpinner = false;
    }
  }
  get recordsAvailable() {
    return (
      Array.isArray(this.records) &&
      this.records.length > 0 &&
      this.statuses.length > 0
    );
  }
  handlePicklistchanged(event) {
    this._recordsUpdatable = true;
    const { context, value } = event.detail.data;
    let updatedItem = {
      returnLineItemId: context,
      status: value,
      updated: true
    };
    this.updateDataValues(updatedItem);
    this.putSessionData();
  }
  updateDataValues(updateItem) {
    let copyData = JSON.parse(JSON.stringify(this.records));
    copyData.forEach((item) => {
      if (item.returnLineItemId === updateItem.returnLineItemId) {
        // eslint-disable-next-line guard-for-in
        for (let field in updateItem) {
          item[field] = updateItem[field];
        }
      }
    });
    //write changes back to original data
    this.records = [...copyData];
    console.log("New ", JSON.parse(JSON.stringify(this.records)));
  }
  loadSessionData() {
    const data = sessionStorage.getItem("data");
    if(!data) return [];
    const records = JSON.parse(data);
    return records;
  }
  async handleSaveChanges() {
    try {
      this.showSpinner = true;
      // Update all records in parallel thanks to the UI API
      const recordUpdatePromises = this.records.slice().map((record) => {
        console.log("New 33", JSON.parse(JSON.stringify(record)));
        const fields = {};
        fields[ID_FIELD.fieldApiName] =record.returnLineItemId;
        fields[STATUS_FIELD.fieldApiName] = record.status;
        const recordInput = { fields };
        return updateRecord(recordInput);
      });

      await Promise.all(recordUpdatePromises);
      // Report success with a toast
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Success",
          message: "Leads successfully updated!",
          variant: "success"
        })
      );
    } catch (error) {
      console.error(error);
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Error updating records",
          message: error,
          variant: "error"
        })
      );
    } finally {
      this.showSpinner = false;
      this._recordsUpdatable = false;
    }
  }
  handleWorkOrderSelection(event){
    let dataRecieved = event.detail.data;
    const selectedId = dataRecieved.selectedId;
    this._recordId  = selectedId;
    this.getRecords(this._recordId)
    .then(() => {})
    .catch(() => {});
  }
}