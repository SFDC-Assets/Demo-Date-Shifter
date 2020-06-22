import { LightningElement, wire, track } from "lwc";
import getOrgObjectList from "@salesforce/apex/DemoDateShifter.getOrgObjectList";
import getDateTimeFields from "@salesforce/apex/DemoDateShifter.getDateTimeFields";
import getMinutesToShift from "@salesforce/apex/DemoDateShifter.getMinutesToShift";

export default class DateSelector extends LightningElement {
	@track orgObjectList = [];
	objectApiName = "";

	@track fieldList = [];
	fieldApiName = "";
	fieldSelectorDisabled = true;

	dateOfDemo = new Date(Date.now()).toISOString();
	dateOfDemoSelected = false;

	loading = true;

	returnedMinutes = 0;
	minutesToShift = 0;
	daysToShift = 0;
	forBack = '';
	shiftAmountVisible = false;

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

	@wire(getDateTimeFields, { objectApiName: "$objectApiName" })
	wired_getFieldList({ error, data }) {
		this.fieldList = [];
		if (data) {
			if (data.length === 0 && this.objectApiName != "") {
				this.template.querySelector("[data-id='field']").placeholder = "No modifiable DateTime fields";
			} else {
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
			}
		} else if (error) {
			this.error = error;
		}
	}

	handleObjectChange(event) {
		this.objectApiName = event.target.value;
		this.fieldApiName = "";
		this.fieldSelectorDisabled = this.objectApiName === "";
		this.shiftAmountVisible = this.fieldApiName != "" && this.dateOfDemoSelected;
	}

	handleFieldChange(event) {
		this.fieldApiName = event.target.value;
		this.shiftAmountVisible = this.fieldApiName != "" && this.dateOfDemoSelected;
	}

	handleDateChange(event) {
		this.dateOfDemo = event.target.value;
		this.dateOfDemoSelected = true;
		getMinutesToShift({ dateOfDemo: this.dateOfDemo, objectApiName: this.objectApiName, fieldApiName: this.fieldApiName })
			.then((result) => {
				this.returnedMinutes = result;
				this.minutesToShift = Math.abs(this.returnedMinutes);
				this.datesToShift = Math.abs(this.returnedMinutes) / 60 / 24;
				this.forBack = this.returnedMinutes < 0 ? "backward" : "forward";
			})
			.catch((error) => {
				this.error = error;
			});
		this.shiftAmountVisible = this.fieldApiName != "" && this.dateOfDemoSelected;
	}
}
