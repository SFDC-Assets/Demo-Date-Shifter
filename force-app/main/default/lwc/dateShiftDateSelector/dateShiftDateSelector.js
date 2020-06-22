import { LightningElement, wire, track, api } from "lwc";
import getOrgObjectList from "@salesforce/apex/DemoDateShifter.getOrgObjectList";
import getDateTimeFields from "@salesforce/apex/DemoDateShifter.getDateTimeFields";

export default class DateSelector extends LightningElement {

	@track orgObjectList = [];
	@api objectApiName = "";

	@track fieldList = [];
	@api fieldApiName = "";
	fieldSelectorDisabled = true;

	dateOfDemo = (new Date(Date.now())).toISOString();

	loading = true;
	
	error;

	@wire(getOrgObjectList)
	wired_getOrgObjectList({ error, data }) {
		this.orgObjectList = [];
		if (data) {
			this.orgObjectList = [];
			data.forEach((object) => {
				this.orgObjectList.push({
					value: object.apiName,
					label: object.label
				});
			});
			this.orgObjectList.sort((a, b) => (a.label > b.label ? 1 : -1));
			this.orgObjectList.unshift({
				value: "",
				label: "Select an object"
			});
			this.loading = false;
		} else if (error) {
			this.error = error;
		}
	}

	@wire(getDateTimeFields, { objectApiName : "$objectApiName" })
	wired_getFieldList({ error, data }) {
		this.fieldList = [];
		if (data && data.length != 0) {
			data.forEach((field) => {
				this.fieldList.push({
					value: field.apiName,
					label: field.label
				});
			});
			this.fieldList.sort((a, b) => (a.label > b.label ? 1 : -1));
			this.fieldList.unshift({
				value: "",
				label: "Select a field"
			});
			this.fieldSelectorDisabled = false;
		} else if (error) {
			this.error = error;
		}
	}

	handleObjectChange(event) {
		this.objectApiName = event.target.value;
		this.fieldSelectorDisabled = this.objectApiName === "";
	}

	handleFieldChange(event) {
		this.fieldApiName = event.target.value;
	}

	handleDateChange(event) {
		this.dateOfDemo = event.target.value;
	}

}
