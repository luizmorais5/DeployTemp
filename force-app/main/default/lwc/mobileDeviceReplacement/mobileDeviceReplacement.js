import { LightningElement, track, api, wire } from "lwc";
import getReturnOrderLineItems from "@salesforce/apex/DeviceController.getReturnOrderLineItems";
import STATUS_FIELD from "@salesforce/schema/ReturnOrderLineItem.Status_list__c";
import ID_FIELD from "@salesforce/schema/ReturnOrderLineItem.Id";
import { updateRecord } from "lightning/uiRecordApi";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

export default class MobileDeviceReplacement extends LightningElement {
  @track records = [];
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
  @track statuses = [{
    label: "Replaced/Collected",
    value:"Replaced/Collected"
  },
  {
    label: "Replaced/Not Collected",
    value:"Replaced/Not Collected"
  },
  {
    label: "Not Replaced",
    value:"Not Replaced"
  },
];

  /**
   * get all assets
   * @param {String} recordId
   */
  async getRecords(recordId) {
    try {
      this.showSpinner = true;
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

  async handleSaveChanges() {
    try {
      this.showSpinner = true;
      // Update all records in parallel thanks to the UI API
      const recordUpdatePromises = this.records.slice().map((record) => {
        console.log("New 33", JSON.parse(JSON.stringify(record)));
        const fields = {};
        fields[ID_FIELD.fieldApiName] = record.returnLineItemId;
        fields[STATUS_FIELD.fieldApiName] = record.status;
        const recordInput = { fields };
        return updateRecord(recordInput);
      });

      await Promise.all(recordUpdatePromises);
      // Report success with a toast
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Success",
          message: "Records successfully updated!",
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
  handleWorkOrderSelection(event) {
    let dataRecieved = event.detail.data;
    const selectedId = dataRecieved.selectedId;
    this._recordId = selectedId;
    this.getRecords(this._recordId)
      .then(() => {})
      .catch(() => {});
  }

  handleStatusChange(event) {
    const deviceId = event.target.dataset.id;
    const newStatus = event.target.value;

    this.updateDataValues({
      returnLineItemId: deviceId,
      status: newStatus
    });
    this._recordsUpdatable = true;
  }
}