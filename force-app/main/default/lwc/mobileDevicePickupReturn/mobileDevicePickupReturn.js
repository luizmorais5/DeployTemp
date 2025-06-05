import { LightningElement, track, api } from "lwc";
import getDevices  from "@salesforce/apex/DeviceController.getPickedUpDevices";
import PICKED_UP_FIELD from "@salesforce/schema/SerializedProduct.Picked_Up__c";
import RETURNED_FIELD from "@salesforce/schema/SerializedProduct.Returned__c";
import ID_FIELD from "@salesforce/schema/SerializedProduct.Id";
import { updateRecord } from "lightning/uiRecordApi";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

export default class MobileDevicePickupReturn extends LightningElement {
  @track records = [];
  @track showPickedUp = false;
  @track showReturned = false;
  @track recordsAvailable = false;
  @track showSpinner = false;
  _recordsUpdatable = false;
  _recordId;

  @api
  set recordId(value) {
    this._recordId = value;
    
  }
  get recordId() {
    return this._recordId;
  }

  
  connectedCallback() {
    this.fetchPickedUpDevices();
  }

  
  async fetchPickedUpDevices() {
    this.showSpinner = true;
    try {
      const data = await getDevices ();
      if (data) {
        this.records = data.terminalIds || [];
        this.recordsAvailable = this.records.length > 0;
        this.showPickedUp = !data.isLogisticUser;
        this.showReturned = data.isLogisticUser;
      }
    } catch (error) {
      console.error("Error fetching picked up devices:", error);
    } finally {
      this.showSpinner = false;
    }
  }

  updateDataValues(updateItem) {
    let copyData = JSON.parse(JSON.stringify(this.records));

    copyData.forEach((item) => {
      if (item.id === updateItem.returnLineItemId) {
        for (let field in updateItem) {
          item[field] = updateItem[field];
        }
      }
    });

    this.records = [...copyData];
  }

  async handleSaveChanges() {
    this.showSpinner = true;
    try {
      const recordUpdatePromises = this.records.map((record) => {
        if (record.serializedProduct && (record.pickedUp || record.returned)) {
          const fields = {
            [ID_FIELD.fieldApiName]: record.serializedProduct,
            [PICKED_UP_FIELD.fieldApiName]: record.pickedUp,
            [RETURNED_FIELD.fieldApiName]: record.returned,
          };
          return updateRecord({ fields });
        }
      });

      await Promise.all(recordUpdatePromises);

      this.dispatchEvent(
        new ShowToastEvent({
          title: "Success",
          message: "Records successfully updated!",
          variant: "success",
        })
      );
    } catch (error) {
      console.error("Error updating records:", error);
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Error",
          message: error.body ? error.body.message : error.message,
          variant: "error",
        })
      );
    } finally {
      this.showSpinner = false;
      this._recordsUpdatable = false;
    }
  }

  handlePickedUpChange(event) {
    const deviceId = event.target.dataset.id;
    const isChecked = event.target.checked;

    this.updateDataValues({
      returnLineItemId: deviceId,
      pickedUp: isChecked,
    });
    this._recordsUpdatable = true;
  }

  handleReturnedChange(event) {
    const deviceId = event.target.dataset.id;
    const isChecked = event.target.checked;

    this.updateDataValues({
      returnLineItemId: deviceId,
      returned: isChecked,
    });
    this._recordsUpdatable = true;
  }
}