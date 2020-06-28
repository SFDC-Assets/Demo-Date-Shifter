import { LightningElement, wire, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getCustomDateShifterSettings from "@salesforce/apex/DemoDateShifter.getCustomDateShifterSettings";
import getOrgObjectList from "@salesforce/apex/DemoDateShifter.getOrgObjectList";
import getDateTimeFields from "@salesforce/apex/DemoDateShifter.getDateTimeFields";
import getMinutesToShift from "@salesforce/apex/DemoDateShifter.getMinutesToShift";

export default class DateSelector extends LightningElement {
	@track orgObjectList = []; // List of date shift objects in the org
	objectApiName = ""; // API name of the object from which to base the shift
	objectSelectorDisabled = false; // True if the object selector is disabled

	@track fieldList = []; // List of fields from which to base the shift
	fieldApiName = ""; // API name of the field from which to base the shift
	fieldSelectorDisabled = true; // True if the field selector is disabled

	dateOfDemo = new Date(Date.now()).toISOString(); // Default value of the date picker
	dateOfDemoSelected = false; // True if the date picker has been used to pick a date
	mostRecent = ""; // Date and time of the most recent record based on the selectors

	loading = true; // True if the selector is loading the objects from the org

	returnedMinutes = 0; // The number of minutes to shift (can be negative)
	returnedDays = 0; // The number of days to shift (can be negative)
	minutesToShift = 0; // The absolute value of minutes to shift
	daysToShift = 0; // The aboslute value of days to shift
	forBack = ""; // "forward" or "backward"
	shiftAmountVisible = false; // Controls whether the explanation of what's going to happen appears

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
			getCustomDateShifterSettings()
				.then((result) => {
					if (result.settingsFound) {
						if (result.objectApiNameIsValid) {
							if (result.fieldApiNameIsValid) {
								this.objectApiName = result.objectApiName;
								this.fieldApiName = result.fieldApiName;
								this.objectSelectorDisabled = true;
							} else
								this.dispatchEvent(
									new ShowToastEvent({
										mode: "sticky",
										variant: "error",
										message:
											`The custom setting "Date_Shifter_Saved_Settings__c" for your profile has an incorrect "Field_API_Name__c" value ("${result.fieldApiName}"). Please correct it or delete it to remove this message.`
									})
								);
						} else {
							this.dispatchEvent(
								new ShowToastEvent({
									mode: "sticky",
									variant: "error",
									message: `The custom setting "Date_Shifter_Saved_Settings__c" for your profile has an incorrect "Object_API_Name__c" value ("${result.objectApiName}"). Please correct it or delete it to remove this message.`
								})
							);
							this.objectSelectorDisabled = false;
							this.fieldApiName = "";
						}
					} else {
						this.objectSelectorDisabled = true;
						this.fieldApiName = "";
					}
				})
				.catch((error) => {
					this.error = error;
				});
			this.fieldSelectorDisabled = true;
			this.loading = false;
		} else if (error) {
			this.error = error;
		}
	}

	@wire(getDateTimeFields, { objectApiName: "$objectApiName" })
	wired_getFieldList({ error, data }) {
		this.fieldList = [];
		if (data) {
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
		} else if (error) {
			this.error = error;
		}
	}

	handleObjectChange(event) {
		this.objectApiName = event.target.value;
		this.fieldApiName = "";
		this.fieldSelectorDisabled = this.objectApiName === "";
		this.shiftAmountVisible = false;
		this.notifyParent(false);
	}

	handleFieldChange(event) {
		this.fieldApiName = event.target.value;
		this.calculateShift();
	}

	handleDateChange(event) {
		this.dateOfDemo = event.target.value;
		this.dateOfDemoSelected = true;
		this.calculateShift();
	}

	calculateShift() {
		if (this.fieldApiName != "" && this.dateOfDemoSelected) {
			getMinutesToShift({ dateOfDemo: this.dateOfDemo, objectApiName: this.objectApiName, fieldApiName: this.fieldApiName })
				.then((result) => {
					this.mostRecent = result.mostRecent;
					this.returnedMinutes = result.minutes;
					this.returnedDays = Math.round(this.returnedMinutes / 60 / 24);
					this.minutesToShift = Math.abs(this.returnedMinutes);
					this.daysToShift = Math.round(Math.abs(this.returnedMinutes) / 60 / 24);
					this.forBack = this.returnedMinutes < 0 ? "backward" : "forward";
					this.shiftAmountVisible = this.fieldApiName != "" && this.dateOfDemoSelected;
					this.notifyParent(this.shiftAmountVisible);
				})
				.catch((error) => {
					this.error = error;
				});
		}
	}

	notifyParent(isSet) {
		this.dispatchEvent(
			new CustomEvent("datefilterchange", {
				detail: {
					isSet: isSet,
					returnedMinutes: this.returnedMinutes,
					returnedDays: this.returnedDays,
					minutesToShift: this.minutesToShift,
					daysToShift: this.daysToShift,
					forBack: this.forBack,
					objectApiName: this.objectApiName,
					fieldApiName: this.fieldApiName,
					dateOfDemo: this.dateOfDemo
				}
			})
		);
	}
}
