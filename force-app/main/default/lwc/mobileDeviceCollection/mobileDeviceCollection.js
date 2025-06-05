import MobileDeviceReplacement from "c/mobileDeviceReplacement";
import { LightningElement, track, api, wire } from "lwc";

export default class MobileDeviceCollection extends MobileDeviceReplacement {
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
        label: "Collected",
        value:"Collected"
      },
      {
        label: "Not Collected",
        value:"Not Collected"
      }
    ];
}