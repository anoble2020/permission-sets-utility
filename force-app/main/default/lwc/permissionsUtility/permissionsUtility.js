import { LightningElement, wire, track } from 'lwc';
import getAllPermissionSets from '@salesforce/apex/PermissionsUtilityController.getAllPermissionSets';
import getFieldPermissions from '@salesforce/apex/PermissionsUtilityController.getFieldPermissions';
import saveFieldPermissions from '@salesforce/apex/PermissionsUtilityController.saveFieldPermissions';
import getAllObjects from '@salesforce/apex/PermissionsUtilityController.getAllObjects';
import getObjectInfos from '@salesforce/apex/PermissionsUtilityController.getObjectInfo';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';

export default class PermissionsUtility extends LightningElement {
    @track permissionSets;
    permissionSetsLoaded;
    objectPermsLoaded;
    @track selectedPermissionSet;
    @track sObjectOptions = [];
    @track sObjectFields = [];
    @track selectedSObject;
    @track permissionSetFields = [];
    @track draftValues = [];
    iconName;
    searchValue;
    @track filteredSObjectFields = [];
    @track objectLevelPerms = [];

    @track allFieldPermissions = [];
    @track allObjectPermissions = [];

    columns = [
        { label: 'Field', fieldName: 'Field', editable: false },
        { label: 'Edit Access', fieldName: 'PermissionsEdit', type: 'boolean', editable: true },
        { label: 'Read Access', fieldName: 'PermissionsRead', type: 'boolean', editable: true },
    ];

    connectedCallback(){
        console.log('loading...');
        this.draftValues = {
            objectPermissions: [], 
            fieldPermissions: []
          };
    }

    @wire(getObjectInfo, { objectApiName: '$selectedSObject' })
    handleResult({error, data}) {
        if(data) {
                let objectInformation = data;

                let iconUrl  = objectInformation.themeInfo.iconUrl;
                let objectIcon = '';

                if (iconUrl && iconUrl.trim() !== '') {
                const urlList = iconUrl.split('/');
                if (urlList.length > 2) {
                    const iconSvg = urlList[urlList.length - 1];
                    const iconName = iconSvg.substring(0, iconSvg.lastIndexOf('_'));
                    this.iconName = `${urlList[urlList.length - 2]}:${iconName}`;
                    const typePath = urlList[urlList.length - 2];
                    console.log('type', typePath);
                    console.log('--iconName--'+JSON.stringify(this.iconName));
                }
            }
        }
        else if(error) {
            // handle error
        }
    }

    @wire(getAllPermissionSets)
    wiredPermissionSets({ error, data }) {
        if (data) {
            this.permissionSets = data.map((permissionSet) => ({
                label: permissionSet.Label,
                value: permissionSet.Id
            }));
            this.permissionSetsLoaded = true;
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

    /*@wire(getObjectInfo, { objectApiName: '$selectedSObject' })
    wiredObjectInfo({ error, data }) {
        if (data) {
            this.loadSObjectFields(data);
        }else if(error){
            console.error(error);
        }
    }*/

    handleSearchChange(event) {
        const searchInput = event.target.value.toLowerCase().trim();
        if (searchInput === '') {
            // If the search input is empty, show all fields
            this.filteredSObjectFields = this.sObjectFields;
        } else {
            // Filter sObjectFields based on the search input
            this.filteredSObjectFields = this.sObjectFields.filter((field) => field.Label.toLowerCase().includes(searchInput));
        }
    }

    handlePermissionSetChange(event) {
        this.selectedPermissionSet = event.detail.value;
        this.selectedSObject = '';
    }

    async handleSObjectChange(event) {
        try{
            this.objectPermsLoaded = false;
            this.selectedSObject = event.detail.value;
            this.objectLevelPerms = [];
            this.draftValues = {
                objectPermissions: [], 
                fieldPermissions: []
              }; // Clear any pending changes

            const objectInfo = await getObjectInfos({ objectApiName: this.selectedSObject });
            console.log('objectInfo', objectInfo);
            await this.loadSObjectFields(objectInfo);
            this.objectPermsLoaded = true;
        }catch(error){
            console.error(error.message);
        }
    }

    setSObjectFields(objectInfo){



        this.objectLevelPerms =   
            {
                type: this.selectedSObject,
                permissions: [
                    {'name' : 'read', 'label' : 'Read', 'value' : this.allObjectPermissions.PermissionsRead || false},
                    {'name' : 'edit', 'label' : 'Edit', 'value' : this.allObjectPermissions.PermissionsEdit || false},
                    {'name' : 'create', 'label' : 'Create', 'value' : this.allObjectPermissions.PermissionsCreate || false},
                    {'name' : 'delete', 'label' : 'Delete', 'value' : this.allObjectPermissions.PermissionsDelete || false},
                    {'name' : 'viewAll', 'label' : 'View All', 'value' : this.allObjectPermissions.PermissionsViewAllRecords || false},
                    {'name' : 'modifyAll', 'label' : 'Modify All', 'value' : this.allObjectPermissions.PermissionsModifyAllRecords || false}
                ]
            }
        ;

        const fieldPermissionsMap = this.createFieldPermissionsMap(this.allFieldPermissions);

        console.log('after field perms', JSON.stringify(fieldPermissionsMap));
        console.log('after object perms', JSON.stringify(this.objectLevelPerms));

        // Populate the sObjectFields array with the dynamic field data
        this.sObjectFields = Object.keys(objectInfo).map(fieldApiName => {
            return {
                Id: fieldApiName,
                SobjectType: this.selectedSObject,
                Label: objectInfo[fieldApiName].Label,
                Disabled: objectInfo[fieldApiName].Permissionable ? false : true,
                Type: objectInfo[fieldApiName].Type,
                PermissionsEdit: fieldPermissionsMap[fieldApiName]?.PermissionsEdit || false,
                PermissionsRead: fieldPermissionsMap[fieldApiName]?.PermissionsRead || false
            };
        });

        this.sObjectFields.sort((a, b) => (a.Label > b.Label ? 1 : -1));
        this.filteredSObjectFields = this.sObjectFields;
        //console.log('filt', JSON.stringify(this.filteredSObjectFields));
    }

    async loadSObjectFields(objectInfo) {
        try{
            const permissions = await getFieldPermissions({
                permissionSetId: this.selectedPermissionSet,
                objectName: this.selectedSObject
            });

            console.log('permissions.objects', JSON.stringify(permissions.objects));

            this.allFieldPermissions = permissions.fields;
            this.allObjectPermissions = permissions.objects[0];

            this.setSObjectFields(objectInfo);

        }catch(error){
            console.error(error.message);
        }
    }

    createFieldPermissionsMap(fieldPermissions) {
        const fieldPermissionsMap = {};

        if(fieldPermissions && fieldPermissions.length){
            fieldPermissions.forEach(permission => {
                console.log('permission', JSON.stringify(permission));
                if (permission && permission.Field) {
                    fieldPermissionsMap[permission.Field.split('.').pop()] = {
                        PermissionsEdit: permission.PermissionsEdit,
                        PermissionsRead: permission.PermissionsRead
                    };
                }
            });
        }
        return fieldPermissionsMap;
    }

    /*createObjectPermissionsMap(objectPermissions) {
        const map = {};
        objectPermissions.forEach(perm => {
          map[perm.SObjectType] = {
            // populate object perm properties
          };
        });
      
        return map;
      }*/

    handleCheckboxChange(event) {
        try{
            console.log('changed', event.target);
            const checkbox = event.target;

            console.log('draftVals', JSON.stringify(this.draftValues));

            if(checkbox.dataset.type === 'object'){

                let objectPerms = this.objectLevelPerms //.find(obj => obj.type === this.selectedSObject);
                objectPerms.permissions.find(obj => obj.name === checkbox.dataset.permission).value = checkbox.checked;

                const perm = 
                    {
                        permission: objectPerms.permissions.find(obj => obj.name === checkbox.dataset.permission).value,
                        read: objectPerms.permissions.find(obj => obj.name === 'read').value,
                        edit: objectPerms.permissions.find(obj => obj.name === 'edit').value,
                        create: objectPerms.permissions.find(obj => obj.name === 'create').value,
                        del: objectPerms.permissions.find(obj => obj.name === 'delete').value,
                        viewAll: objectPerms.permissions.find(obj => obj.name === 'viewAll').value,
                        modifyAll: objectPerms.permissions.find(obj => obj.name === 'modifyAll').value,
                        objType: this.selectedSObject, 
                        permSet: this.selectedPermissionSet
                    };

                const index = this.draftValues.objectPermissions?.findIndex(objPerm => objPerm.objType === this.selectedSObject);

                if(index && index > 0){
                    this.draftValues.objectPermissions[index] = perm;
                }else{
                    this.draftValues.objectPermissions.push(perm);
                }

                /*this.objectLevelPerms.find(obj => obj.name === checkbox.dataset.permission).value = checkbox.checked;
                console.log('obj level perms here', JSON.stringify(this.objectLevelPerms));*/


                //TESTING! 

                /*
                let existingObjPerm = this.draftValues.objectPermissions?.find(objPerm => objPerm.objType == this.selectedSObject);

                if(existingObjPerm){
                    console.log('perm found', JSON.stringify(existingObjPerm));
                    existingObjPerm = { 
                        read: this.objectLevelPerms.find(obj => obj.name === 'Read').value,
                        edit: this.objectLevelPerms.find(obj => obj.name === 'Edit').value,
                        view: this.objectLevelPerms.find(obj => obj.name === 'Create').value,
                        del: this.objectLevelPerms.find(obj => obj.name === 'Delete').value,
                        viewAll: this.objectLevelPerms.find(obj => obj.name === 'View All').value,
                        modifyAll: this.objectLevelPerms.find(obj => obj.name === 'Modify All').value,
                        objType: this.selectedSObject, 
                        permSet: this.selectedPermissionSet
                    };
                }else{
                    console.log('draft values when no values', JSON.stringify(this.draftValues));
                    this.draftValues.objectPermissions.push({ 
                        read: this.objectLevelPerms.find(obj => obj.name === 'Read').value,
                        edit: this.objectLevelPerms.find(obj => obj.name === 'Edit').value,
                        view: this.objectLevelPerms.find(obj => obj.name === 'Create').value,
                        del: this.objectLevelPerms.find(obj => obj.name === 'Delete').value,
                        viewAll: this.objectLevelPerms.find(obj => obj.name === 'View All').value,
                        modifyAll: this.objectLevelPerms.find(obj => obj.name === 'Modify All').value,
                        objType: this.selectedSObject, 
                        permSet: this.selectedPermissionSet
                    });
                }*/

            }else{
                const fieldName = checkbox.dataset.fieldName; // Get the field API name from the dataset
                console.log('fieldName', fieldName);

                const type = checkbox.name; // "read" or "edit"
                console.log('type', type);

                let read;
                let edit;

                if(type === 'read'){
                    read = checkbox.checked;
                }

                if(type === 'edit'){
                    edit = checkbox.checked;

                    if (edit) {
                        // If "edit" is checked, also set "read" to true
                        read = true;

                        // Update the UI for the "read" checkbox
                        const readCheckbox = this.template.querySelector(`[data-field-name="${fieldName}"][name="read"]`);
                        if (readCheckbox) {
                            readCheckbox.setAttribute('checked', '');
                        }
                    }
                }

                const completeFieldName = this.selectedSObject + '.' + fieldName;

                // Update the draftValues array based on the checkbox change
                this.draftValues = this.draftValues.fieldPermissions.filter(item => item.fieldApiName !== completeFieldName); // Remove previous values for the field
                this.draftValues.fieldPermissions.push({ 
                    fieldApiName: completeFieldName, 
                    objType: this.selectedSObject, 
                    permSet: this.selectedPermissionSet,
                    read: read ? read : this.sObjectFields[fieldName]?.PermissionsRead || false,
                    edit: edit ? edit : this.sObjectFields[fieldName]?.PermissionsEdit || false
                });
                console.log('drafts', JSON.stringify(this.draftValues));
            }
        }catch(error){
            console.error(error.message);
        }
    }

    handleSave() {
        if (this.draftValues.objectPermissions.length > 0 || this.draftValues.fieldPermissions.length > 0) {
            console.log('saving...');
            // Call the Apex method to save the field permissions
            saveFieldPermissions({ fieldPermissions: JSON.stringify(this.draftValues) })
                .then(result => {
                    // Handle any response from the Apex method if needed
                    this.draftValues = {objectpermissions: [], fieldPermissions: []};
                    this.loadSObjectFields();            
                })
                .catch(error => {
                    // Handle errors if any
                });
        }
    }

    get showButtons(){
        return this.draftValues.objectPermissions?.length || this.draftValues.fieldPermissions?.length
    }

    handleCancel(){
        this.draftValues = {objectpermissions: [], fieldPermissions: []};
        this.setSObjectFields();
    }
}
