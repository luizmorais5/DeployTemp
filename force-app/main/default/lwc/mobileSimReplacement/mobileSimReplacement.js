import { LightningElement, track, api, wire } from "lwc";
import getReturnOrderLineItems from "@salesforce/apex/DeviceController.getReturnOrderLineItems";
import { getObjectInfo } from "lightning/uiObjectInfoApi";
import ReturnOrderLineItem from "@salesforce/schema/ReturnOrderLineItem";
import SIM_Card_1_Text from "@salesforce/schema/ReturnOrderLineItem.SIM_Card_1_text__c";
import SIM_Card_2_Text from "@salesforce/schema/ReturnOrderLineItem.SIM_Card_2_text__c";
import SIM_Card_1_Status from "@salesforce/schema/ReturnOrderLineItem.SIM_Card_1_Status_list__c";
import SIM_Card_2_Status from "@salesforce/schema/ReturnOrderLineItem.SIM_Card_2_Status_list__c";
import ID_FIELD from "@salesforce/schema/ReturnOrderLineItem.Id";
import { updateRecord } from "lightning/uiRecordApi";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
export default class MobileSimReplacement extends LightningElement {
  @track sim1StatusOptions = [
    { label: "Collected", value: "Collected", text: "Collected" },
    { label: "Not Collected", value: "Not Collected", text: "Not Collected" }
  ];
  @track sim2StatusOptions = this.sim1StatusOptions;
  showSpinner = false;
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

  @wire(getObjectInfo, { objectApiName: ReturnOrderLineItem })
  objectInfo;

  //   @wire(getPicklistValues, {
  //     recordTypeId: "$objectInfo.data.defaultRecordTypeId",
  //     fieldApiName: SIM1_STATUS
  //   })
  //   wiredSIM1_STATUS({ data, error }) {
  //     if (error) {
  //       this.sim1Statuses = [];
  //     } else if (data) {
  //       this.sim1Statuses = data.values.map((record) => ({
  //         label: record.label,
  //         value: record.value,
  //         text: record.value
  //       }));
  //       console.info("states: " + JSON.stringify(this.sim1Statuses));
  //     }
  //   }
  //   @wire(getPicklistValues, {
  //     recordTypeId: "$objectInfo.data.defaultRecordTypeId",
  //     fieldApiName: SIM2_STATUS
  //   })
  //   wiredSIM2_STATUS({ data, error }) {
  //     if (error) {
  //       this.sim2Statuses = [];
  //     } else if (data) {
  //       this.sim2Statuses = data.values.map((record) => ({
  //         label: record.label,
  //         value: record.value,
  //         text: record.value
  //       }));
  //     }
  //   }
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
          ...returnLineItem.asset,
          ...returnLineItem,
          notAllowSim1Input: false,
          notAllowSim2Input: false
        });
      }
      console.info("Records", JSON.parse(JSON.stringify(this.records)));
    } catch (error) {
      console.warn(error);
    } finally {
      this.showSpinner = false;
    }
  }
  handleSimcard1StatusChange(event) {
    const deviceId = event.target.dataset.id;
    const value = event.target.value;
    this.updateDataValues({
      returnLineItemId: deviceId,
      simCard1Status: value,
      notAllowSim1Input: value === "Collected"
    });
  }
  handleSimcard2StatusChange(event) {
    const deviceId = event.target.dataset.id;
    const value = event.target.value;
    this.updateDataValues({
      returnLineItemId: deviceId,
      simCard2Status: value,
      notAllowSim2Input: value === "Collected"
    });
  }
  handleSimcard1Change(event) {
    const deviceId = event.target.dataset.id;
    const value = event.detail.value;
    console.log("Changed device", deviceId, value);
    this.updateDataValues({
      returnLineItemId: deviceId,
      simCard1Value: value
    });
    this._recordsUpdatable = true;
  }
  handleSimcard2Change(event) {
    const deviceId = event.target.dataset.id;
    const value = event.detail.value;
    console.log("Changed device", deviceId, value);
    this.updateDataValues({
      returnLineItemId: deviceId,
      simCard2Value: value
    });
    this._recordsUpdatable = true;
  }
  get recordsAvailable() {
    return (
      Array.isArray(this.records) &&
      this.records.length > 0 &&
      this.sim1StatusOptions.length > 0 &&
      this.sim2StatusOptions.length > 0
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
        fields[SIM_Card_1_Text.fieldApiName] = record.simCard1Value;
        fields[SIM_Card_2_Text.fieldApiName] = record.simCard2Value;
        fields[SIM_Card_1_Status.fieldApiName] = record.simCard1Status;
        fields[SIM_Card_2_Status.fieldApiName] = record.simCard2Status;
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
}