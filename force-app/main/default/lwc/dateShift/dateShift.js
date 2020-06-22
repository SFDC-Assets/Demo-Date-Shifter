import { LightningElement, wire, track } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import { subscribe, unsubscribe } from "lightning/empApi";
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
				subscribe("/event/Date_Shift_Event__e", -1, (event) => {
					this.handleBatchEvent(event);
				}).then((result) => {
					console.log(`subscribed, result: ${JSON.stringify(result)}`);
					this.subscription = result;
				});
				this.shiftInProgress = true;
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

	handleBatchEvent(event) {
		console.log(`got batch event: ${JSON.stringify(event)}`);
		const sObjectAPI = event.data.payload.SObject_API_Name__c;
		const runningTotal = event.data.payload.Running_Total__c;
		const numberOfErrors = event.data.payload.Errors__c;
		let objectList = this.objectList;
		let dateShiftFinished = true;
		let dateShiftHadErrors = false;
		objectList.forEach((dso) => {
			if (dso.itemAPIName == sObjectAPI) {
				dso.itemRunningTotal = runningTotal;
				dso.itemNumberOfErrors = numberOfErrors;
				dso.itemShiftFinished = runningTotal >= dso.itemCount;
				dso.itemRemaining = dso.itemCount - dso.itemRunningTotal;
				dso.itemPercentage = (100 * dso.itemRunningTotal) / dso.itemCount;
			}
			dateShiftFinished = dateShiftFinished && dso.itemShiftFinished;
			dateShiftHadErrors = dateShiftHadErrors || dso.itemNumberOfErrors > 0;
		});
		this.dateShiftFinished = dateShiftFinished;
		this.dateShiftHadErrors = dateShiftHadErrors;
		this.objectList = objectList;
		if (dateShiftFinished) {
			unsubscribe(this.subscription, (result) => {
				this.subscription = null;
			});
			if (dateShiftHadErrors)
				this.dispatchEvent(
					new showToastEvent({
						mode: "sticky",
						variant: "error",
						message: "Errors occurred during the date shift. Please check the system debug log for details.\n" + "All records without errors were date shifted correctly."
					})
				);
			this.dispatchEvent(
				new showToastEvent({
					mode: "sticky",
					variant: "success",
					title: "Date shifting has completed.",
					message:
						"Make sure that you run the Einstein Analytics dataflows that contain the records you shifted so that your dashboards will reflect the shifted dates.\n" +
						"If you have any questions about how to do that, please consult one of your team's Einstein Analytics Blackbelts."
				})
			);
		}
	}
}
