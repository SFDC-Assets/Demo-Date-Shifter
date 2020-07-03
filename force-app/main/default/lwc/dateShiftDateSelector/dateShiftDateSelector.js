import { LightningElement, wire, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getCustomDateShifterSettings from "@salesforce/apex/DemoDateShifter.getCustomDateShifterSettings";
import setCustomDateShifterSettings from "@salesforce/apex/DemoDateShifter.setCustomDateShifterSettings";
import deleteCustomDateShifterSettings from "@salesforce/apex/DemoDateShifter.deleteCustomDateShifterSettings";
import getOrgObjectList from "@salesforce/apex/DemoDateShifter.getOrgObjectList";
import getDateTimeFields from "@salesforce/apex/DemoDateShifter.getDateTimeFields";
import getMinutesToShift from "@salesforce/apex/DemoDateShifter.getMinutesToShift";

export default class DateSelector extends LightningElement {
	@track orgObjectList = [];
	objectApiName = "";
	objectSelectorDisabled = false;

	@track fieldList = [];
	fieldApiName = "";
	fieldSelectorDisabled = true;

	savedSettingsFound = false;
	saveSettingsButtonDisabled = true;
	showSaveSettingsButton = true;

	dateOfDemo = new Date(Date.now()).toISOString();
	dateOfDemoSelected = false;
	mostRecent = "";

	loading = true;

	returnedMinutes = 0;
	returnedDays = 0;
	minutesToShift = 0;
	daysToShift = 0;
	forBack = "";
	shiftAmountVisible = false;

	error;

	@wire(getOrgObjectList)
	wired_getOrgObjectList({ data, error }) {
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
								this.savedSettingsFound = true;
								this.showSaveSettingsButton = false;
							} else {
								this.dispatchEvent(
									new ShowToastEvent({
										mode: "sticky",
										variant: "error",
										message: `The custom setting "Date_Shifter_Saved_Settings__c" for your profile has an incorrect "Field_API_Name__c" value ("${result.fieldApiName}"). Please correct it or delete it to remove this message.`
									})
								);
								this.saveSettingsButtonDisabled = true;
							}
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
							this.saveSettingsButtonDisabled = true;
						}
					} else {
						this.showSaveSettingsButton = true;
						this.objectSelectorDisabled = false;
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
	wired_getFieldList({ data, error }) {
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
		this.showSaveSettingsButton = true;
		this.saveSettingsButtonDisabled = true;
		this.notifyParent(false);
	}

	handleFieldChange(event) {
		this.fieldApiName = event.target.value;
		this.calculateShift();
		this.showSaveSettingsButton = true;
		this.saveSettingsButtonDisabled = this.fieldApiName === "";
	}

	handleDateChange(event) {
		this.dateOfDemo = event.target.value;
		this.dateOfDemoSelected = true;
		this.calculateShift();
	}

	handleSaveSettingsButton(event) {
		setCustomDateShifterSettings({ objectApiName: this.objectApiName, fieldApiName: this.fieldApiName }).then((result) => {
			this.dispatchEvent(
				new ShowToastEvent({
					variant: "success",
					message: "Your settings have been saved."
				})
			);
			this.showSaveSettingsButton = false;
			this.savedSettingsFound = true;
			this.objectSelectorDisabled = true;
			this.fieldSelectorDisabled = true;
		});
	}

	handleClearSettingsButton(event) {
		deleteCustomDateShifterSettings().then((result) => {
			this.dispatchEvent(
				new ShowToastEvent({
					variant: "success",
					message: "Your saved settings have been removed."
				})
			);
			this.showSaveSettingsButton = true;
			this.savedSettingsFound = true;
			this.objectSelectorDisabled = false;
			this.fieldSelectorDisabled = false;
		});
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
