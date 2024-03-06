import { LightningElement, track, wire } from 'lwc';
import getAllPermissionSets from '@salesforce/apex/PermissionsUtilityController.getAllPermissionSets';
import getAllObjects from '@salesforce/apex/PermissionsUtilityController.getAllObjects';

export default class PermissionsContainer extends LightningElement {
    @track permissionSets;
    @track selectedPermissionSet;
    @track sObjectOptions = [];
    @track selectedSObject;

    @wire(getAllPermissionSets)
    wiredPermissionSets({ error, data }) {
        if (data) {
            this.permissionSets = data.map((permissionSet) => ({
                label: permissionSet.Label,
                value: permissionSet.Id
            }));
        }
    }

    @wire(getAllObjects)
    wiredSObjectMap({ error, data }) {
        if (data) {
            this.sObjectOptions = Object.keys(data).map(key => ({
                label: data[key],
                value: key
            }));
        }
    }

    handlePermissionSetChange(event) {
        this.selectedPermissionSet = event.detail.value;
        this.selectedSObject = '';
    }

    handleSObjectChange(event) {
        this.selectedSObject = event.detail.value;
    }
}