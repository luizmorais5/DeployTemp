import LightningDatatable from 'lightning/datatable';
import InputSearcher from './lookup.html';
import lookupColumn from './lookupColumn.html';
export default class CustomTable extends LightningDatatable {
    static customTypes = {
        lookup: {
            template: InputSearcher,
            standardCellLayout: true,
            typeAttributes: ['lookupLabel', 'objectApiName', 'iconName']
        },
        lookupColumn: {
            template: lookupColumn,
            standardCellLayout: true,
            typeAttributes: ['value', 'fieldName', 'object', 'context', 'name', 'fields', 'target']
        }
    };
}