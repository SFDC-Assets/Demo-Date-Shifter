import { LightningElement, wire, track } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import getObjectItems from "@salesforce/apex/DemoDateShifter.getObjectItems";
import dateShift from "@salesforce/apex/DemoDateShifter.dateShift";

export default class DateShift extends NavigationMixin(LightningElement) {
	columns = [
		{ label: "Records", fieldName: "itemCount", type: "number", initialWidth: 100, cellAttributes: { alignment: "right" } },
		{ label: "Weekdays Only", fieldName: "itemWeekdaysOnly", type: "boolean", initialWidth: 120, cellAttributes: { alignment: "center" } },
		{ label: "Adjust Minutes", fieldName: "itemAdjustMinutes", type: "boolean", initialWidth: 120, cellAttributes: { alignment: "center" } },
		{
			label: "Object",
			fieldName: "itemLink",
			type: "url",
			cellAttributes: { iconName: "standard:shift", alignment: "left" },
			typeAttributes: { label: { fieldName: "itemLabel" }, tooltip: { fieldName: "itemLabelPlural" }, target: "_parent" }
		}
	];

	@track objectList = [];
	objectListIsEmpty = true;

	minutesToShift = 0;
	daysToShift = 0;
	forBack = "";
	dateOfDemo = "";
	dateFilterNotSet = true;

	shiftInProgress = false;
	dateShiftFinished = false;
	dateShiftHadErrors = false;

	objectApiName;
	fieldApiName;

	helpSectionVisible = false;

	subscription;

	error;

	@wire(getObjectItems)
	wired_getObjectItems({ error, data }) {
		if (data) {
			this.objectList = data;
			this.objectListIsEmpty = this.objectList.length == 0;
		} else if (error) {
			this.error = error;
		}
	}

	handleDateShiftObjectClick() {
		this[NavigationMixin.Navigate]({
			type: "standard__objectPage",
			attributes: {
				objectApiName: "Date_Shift_Object__c",
				actionName: "list"
			},
			state: {
				filterName: "All"
			}
		});
	}

	handleShiftDatesButton() {
		dateShift({ dateOfDemo: this.dateOfDemo, objectApiName: this.objectApiName, fieldApiName: this.fieldApiName })
			.then((result) => {
				result.forEach((toast) => {
					this.dispatchEvent(
						new ShowToastEvent({
							mode: toast.toastMode,
							variant: toast.toastVariant,
							message: toast.toastMessage
						})
					);
				});
			})
			.catch((error) => {
				this.error = error;
			});
	}

	handleHelpButton() {
		this.helpSectionVisible = !this.helpSectionVisible;
	}

	handleDateFilterChange(event) {
		this.dateFilterNotSet = !event.detail.isSet;
		this.minutesToShift = event.detail.minutesToShift;
		this.daysToShift = event.detail.daysToShift;
		this.forBack = event.detail.forBack;
		this.objectApiName = event.detail.objectApiName;
		this.fieldApiName = event.detail.fieldApiName;
		this.dateOfDemo = event.detail.dateOfDemo;
	}
}
