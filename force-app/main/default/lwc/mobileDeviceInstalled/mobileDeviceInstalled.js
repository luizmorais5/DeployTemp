import { LightningElement, track, api, wire } from "lwc";
import getTerminalIds from "@salesforce/apex/DeviceController.getTerminalIds";
import updateRecords from "@salesforce/apex/DeviceController.updateRecords";
import INSTALLED_FIELD from "@salesforce/schema/SerializedProduct.Installed__c";
import REASON_FIELD from "@salesforce/schema/SerializedProduct.Not_Installed_Reason__c";
import ID_FIELD from "@salesforce/schema/SerializedProduct.Id";
import { updateRecord } from "lightning/uiRecordApi";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

export default class MobileDeviceInstalled extends LightningElement {
  @track records = [];
  @track showSpinner = false;
  _recordsUpdatable = false;
  _recordId;
  @track errorMessage;
  @api
  set recordId(value) {
    this._recordId = value;
    this.getRecords(value)
      .then(() => {})
      .catch(() => {});
  }
  get recordId() {
    console.log('this._recordId = '+this._recordId);
    return this._recordId;
  }
  message;

@track reasons = [{
    label: "Select an Option",
    value:"Select an Option"
  },
  {
    label: "Defective Device",
    value:"Defective Device"
  },
  {
    label: "Merchant Rejected Installation of Device",
    value:"Merchant Rejected Installation of Device"
  },
  {
    label: "Features Not Applicable",
    value:"Features Not Applicable"
  },
  {
    label: "Connectivity Issue",
    value:"Connectivity Issue"
  },
  {
    label: "Other",
    value:"Other"
  },
];

  async refreshRecords() {
    this.records = [];
    this.showSpinner = true;
    await this.getRecords(this._recordId);
  }

  /**
   * get all assets
   * @param {String} recordId
   */
  async getRecords(recordId) {
    try {
    console.log('recordId = '+recordId);

      this.showSpinner = true;
      this.records = [];
      const response = await getTerminalIds({ recordIds: [recordId] });
      console.log('#response = '+ JSON.stringify(response));
      // this.records = response;
      for (const returnLineItem of response) {
      console.log('#returnLineItem = '+ JSON.stringify(returnLineItem));
      let reasonValue = '';

      //If case is closed, then the table should not be updatable.
      if(returnLineItem.isCaseClosed){
        this._recordsUpdatable = false;
        returnLineItem.reasonDisabled = true;
        returnLineItem.installedDisabled = true;
      }else if(returnLineItem.notInstalledReason){
        returnLineItem.installedDisabled = true;
        returnLineItem.reasonDisabled = false;
      } else if(returnLineItem.installed == true){
        returnLineItem.reasonDisabled = true;
        returnLineItem.installedDisabled = false;
      }

      if(returnLineItem.reason == '' || returnLineItem.reason == null){
        reasonValue = 'Select an Option';
      }

        this.records.push({
          returnLineItemId: returnLineItem.id,
          reason: reasonValue,
          ...returnLineItem
        });
      }
    } catch (error) {
      errorMessage = JSON.stringify(error);
      console.log('Error');
      console.warn(error);
      this.showSpinner = false;
    } finally {
      this.showSpinner = false;
    }
  }
  get recordsAvailable() {
    console.log('# recordsAvailable this.records = '+ JSON.stringify(this.records));

    return (
      Array.isArray(this.records) &&
      this.records.length > 0
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

      updateRecords({
        jsonRecords: JSON.stringify(this.records),
        workOrderLineItemId: this._recordId
      })
      .then((data) => {
        this.dispatchEvent(
          new ShowToastEvent({
            title: "Success",
            message: "Records successfully updated!",
            variant: "success"
          })
        );

        this.refreshRecords();
      })
      .catch((error) => {
        console.error(error);
        const message = error.body.pageErrors && error.body.pageErrors.length > 0 
          ? error.body.pageErrors[0].message 
          : error.body.message || "An unknown error occurred.";
          this.dispatchEvent(
              new ShowToastEvent({
                  title: "Error updating records",
                  message: message,
                  variant: "error"
              })
        );
      }).finally(() => {
      this.showSpinner = false;
      this._recordsUpdatable = false;
    });
    } catch (error) {
      console.error(error);
      const message = error.body.pageErrors && error.body.pageErrors.length > 0 
          ? error.body.pageErrors[0].message 
          : error.body.message || "An unknown error occurred.";
      this.dispatchEvent(
          new ShowToastEvent({
              title: "Error updating records",
              message: message,
              variant: "error"
          })
      );

      this.showSpinner = false;
      this._recordsUpdatable = false;
    }
  }
  // handleWorkOrderSelection(event) {
  //   let dataRecieved = event.detail.data;
  //   const selectedId = dataRecieved.selectedId;
  //   this._recordId = selectedId;
  //   console.log("## dataRecieved", JSON.stringify(dataRecieved));
  //   console.log("## selectedId", JSON.stringify(selectedId));
  //   console.log("## this._recordId", JSON.stringify(this._recordId));

  //   this.getRecords(this._recordId)
  //     .then(() => {})
  //     .catch(() => {});
  // }

  handleInstalledChange(event) {
    const deviceId = event.target.dataset.id;
    const newStatus = event.target.value;
    let installedDisabled = false;
    let reasonDisabled = false;
    let createProductConsumption = false;
    let deleteProductConsumption = false;

    if(event.target.checked){
      installedDisabled = false;
      reasonDisabled = true;
      createProductConsumption = true
    } else {
      reasonDisabled = false;
      deleteProductConsumption = true;
    }

    this.updateDataValues({
      returnLineItemId: deviceId,
      installed: event.target.checked,
      installedDisabled: installedDisabled,
      reasonDisabled: reasonDisabled,
      createProductConsumption: createProductConsumption,
      deleteProductConsumption: deleteProductConsumption
    });
    if(!event.target.checked){
      this._recordsUpdatable = true;
    } else {
      this._recordsUpdatable = true;
    }
  }

  handleReasonChange(event) {
    const deviceId = event.target.dataset.id;
    const newReason = event.target.value;
    let installedDisabled = false;
    let reasonDisabled = false;

    if(newReason != 'Select an Option'){
      installedDisabled = true;
      reasonDisabled = false;
      this._recordsUpdatable = true;
    } else {
      installedDisabled = false;
      reasonDisabled = false;
      this._recordsUpdatable = false;
    }

    this.updateDataValues({
      returnLineItemId: deviceId,
      reason: newReason,
      installedDisabled: installedDisabled,
      reasonDisabled: reasonDisabled
    });
  }

}