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

	startingDateShift = false;
	shiftInProgress = false;
	dateShiftFinished = false;
	dateShiftHadErrors = false;

	objectApiName;
	fieldApiName;

	helpSectionVisible = false;

	subscription = {};

	error;

	@wire(getObjectItems)
	wired_getObjectItems({ error, data }) {
		if (data) {
			this.objectList = [];
			data.forEach((dso) => {
				this.objectList.push({
					itemId: dso.itemId,
					itemAPIName: dso.itemAPIName,
					itemLabel: dso.itemLabel,
					itemLabelPlural: dso.itemLabelPlural,
					itemWeekdaysOnly: dso.itemWeekdaysOnly,
					itemAdjustMinutes: dso.itemAdjustMinutes,
					itemLink: dso.itemLink,
					itemCount: dso.itemCount,
					itemRunningTotal: dso.itemRunningTotal,
					itemNumberOfErrors: dso.itemNumberOfErrors,
					itemRemaining: dso.itemRemaining,
					itemPercentage: dso.itemPercentage,
					itemShiftFinished: dso.itemShiftFinished
				});
			});
			this.objectListIsEmpty = this.objectList.length === 0;
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
		this.startingDateShift = true;
		dateShift({ dateOfDemo: this.dateOfDemo, objectApiName: this.objectApiName, fieldApiName: this.fieldApiName })
			.then((result) => {
				//console.log(`dateShift returned good result: ${JSON.stringify(result)}`);
				result.forEach((toast) => {
					this.dispatchEvent(
						new ShowToastEvent({
							mode: toast.toastMode,
							variant: toast.toastVariant,
							message: toast.toastMessage
						})
					);
				});
				subscribe("/event/Date_Shift_Event__e", -1, this.handleBatchEvent.bind(this)).then((result) => {
					this.subscription = result;
				});
				this.shiftInProgress = true;
			})
			.catch((error) => {
				this.error = error;
			});
		this.startingDateShift = false;
	}

	handleHelpButton() {
		this.helpSectionVisible = !this.helpSectionVisible;
	}

	handleDateFilterChange(event) {
		console.log(`event received: ${JSON.stringify(event.detail)}`);
		this.dateFilterNotSet = !event.detail.isSet;
		this.minutesToShift = event.detail.minutesToShift;
		this.daysToShift = event.detail.daysToShift;
		this.forBack = event.detail.forBack;
		this.objectApiName = event.detail.objectApiName;
		this.fieldApiName = event.detail.fieldApiName;
		this.dateOfDemo = event.detail.dateOfDemo;
	}

	handleBatchEvent(event) {
		//console.log(`event = ${JSON.stringify(event)}`);
		//console.log(`this.objectList = ${JSON.stringify(this.objectList)}`);
		let dateShiftFinished = true;
		let dateShiftHadErrors = false;
		this.objectList.forEach((dso) => {
				if (dso.itemAPIName === event.data.payload.SObject_API_Name__c) {
					dso.itemRunningTotal = event.data.payload.Running_Total__c;
					dso.itemNumberOfErrors = event.data.payload.Errors__c;
					dso.itemShiftFinished = dso.itemRunningTotal >= dso.itemCount;
					dso.itemRemaining = dso.itemCount - dso.itemRunningTotal;
					dso.itemPercentage = (100 * dso.itemRunningTotal) / dso.itemCount;
					console.log(`dso = ${JSON.stringify(dso)}`);
				}
			dateShiftFinished = dateShiftFinished && dso.itemShiftFinished;
			dateShiftHadErrors = dateShiftHadErrors || dso.itemNumberOfErrors > 0;
		});
		this.dateShiftFinished = dateShiftFinished;
		this.dateShiftHadErrors = dateShiftHadErrors;
		if (dateShiftFinished) {
			unsubscribe(this.subscription, (result) => {
				console.log("Batch event unsubscribed.");
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
