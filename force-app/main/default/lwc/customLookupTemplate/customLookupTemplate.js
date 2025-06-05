// customLookupTemplate.js
import { LightningElement, api, wire } from "lwc";

export default class CustomLookupTemplate extends LightningElement {
  draftValues = [];
  columns = [
    {
      label: "Close Date",
      fieldName: "CloseDate",
      type: "date-local",
      typeAttributes: {
        day: "numeric",
        month: "numeric",
        year: "numeric"
      },
      editable: true
    },
    {
      label: "Asset Name",
      fieldName: "Name",
      type: "lookup",
      typeAttributes: {
        placeholder: "Choose Asset",
        object: "Asset",
        fieldName: "AssetName",
        label: "Asseet",
        value: { fieldName: "Name" },
        context: { fieldName: "Id" },
        variant: "label-hidden",
        name: "Asseet",
        fields: ["Asset.Name"],
        target: "_self"
      },
      editable: true,
      cellAttributes: {
        class: { fieldName: "accountNameClass" }
      }
    }
  ];
  records = [
    {
      Id: "1",
      CloseDate: new Date(),
      AccountId: ""
    }
  ];
  renderedCallback() {
    if (!this.isComponentLoaded) {
        /* Add Click event listener to listen to window click to reset the lookup selection 
        to text view if context is out of sync*/
        window.addEventListener('click', (evt) => {
            this.handleWindowOnclick(evt);
        });
        this.isComponentLoaded = true;
    }
}

disconnectedCallback() {
    window.removeEventListener('click', () => { });
}

handleWindowOnclick(context) {
    this.resetPopups('c-datatable-lookup', context);
}

  //Captures the changed lookup value and updates the records list variable.
  handleValueChange(event) {
    event.stopPropagation();
    let dataRecieved = event.detail.data;
    let updatedItem;
    switch (dataRecieved.label) {
      case "Account":
        updatedItem = {
          Id: dataRecieved.context,
          AccountId: dataRecieved.value
        };
        // Set the cell edit class to edited to mark it as value changed.
        this.setClassesOnData(
          dataRecieved.context,
          "accountNameClass",
          "slds-cell-edit slds-is-edited"
        );
        break;
      default:
        this.setClassesOnData(dataRecieved.context, "", "");
        break;
    }
    this.updateDraftValues(updatedItem);
    this.updateDataValues(updatedItem);
  }
  updateDataValues(updateItem) {
    let copyData = JSON.parse(JSON.stringify(this.records));
    copyData.forEach((item) => {
      if (item.Id === updateItem.Id) {
        for (let field in updateItem) {
          item[field] = updateItem[field];
        }
      }
    });
    this.records = [...copyData];
  }

  updateDraftValues(updateItem) {
    let draftValueChanged = false;
    let copyDraftValues = JSON.parse(JSON.stringify(this.draftValues));
    copyDraftValues.forEach((item) => {
      if (item.Id === updateItem.Id) {
        for (let field in updateItem) {
          item[field] = updateItem[field];
        }
        draftValueChanged = true;
      }
    });
    if (draftValueChanged) {
      this.draftValues = [...copyDraftValues];
    } else {
      this.draftValues = [...copyDraftValues, updateItem];
    }
  }
  handleCellChange(event) {
    event.preventDefault();
    this.updateDraftValues(event.detail.draftValues[0]);
  }

  handleSave(event) {
    event.preventDefault();
  }
  handleEdit(event) {
    event.preventDefault();
    let dataRecieved = event.detail.data;
    this.handleWindowOnclick(dataRecieved.context);
    switch (dataRecieved.label) {
      case "Account":
        this.setClassesOnData(
          dataRecieved.context,
          "accountNameClass",
          "slds-cell-edit"
        );
        break;
      default:
        this.setClassesOnData(dataRecieved.context, "", "");
        break;
    }
  }

  setClassesOnData(id, fieldName, fieldValue) {
    this.records = JSON.parse(JSON.stringify(this.records));
    this.records.forEach((detail) => {
      if (detail.Id === id) {
        detail[fieldName] = fieldValue;
      }
    });
  }
}