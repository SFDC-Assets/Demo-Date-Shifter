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

	subscription;

	error;

	@wire(getObjectItems)
	wired_getObjectItems({ error, data }) {
		if (data) {
			this.objectList = data;
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
				console.log(`dateShift returned good result: ${JSON.stringify(result)}`);
				result.forEach((toast) => {
					this.dispatchEvent(
						new ShowToastEvent({
							mode: toast.toastMode,
							variant: toast.toastVariant,
							message: toast.toastMessage
						})
					);
				});
				subscribe("/event/Date_Shift_Event__e", -1, (response) => {
					this.handleBatchEvent(this, response);
				}).then((result) => {
					console.log(`subscribed, result: ${JSON.stringify(result)}`);
					this.subscription = result;
				});
				this.shiftInProgress = true;
			})
			.catch((error) => {
				console.log(`dateShift returned error: ${JSON.stringify(error)}`);
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

	handleBatchEvent(component, event) {
		console.log(`in receiveBatchEvent, event = ${JSON.stringify(event)}`);
		console.log(`component.objectList = ${JSON.stringify(component.objectList)}`);
		let dateShiftFinished = true;
		let dateShiftHadErrors = false;
		for (let dso of component.objectList) {
			try {
				if (dso.itemAPIName === event.data.payload.SObject_API_Name__c) {
					dso.itemRunningTotal = event.data.payload.runningTotal;
					dso.itemNumberOfErrors = event.data.payload.numberOfErrors;
					dso.itemShiftFinished = event.data.payload.runningTotal >= dso.itemCount;
					dso.itemRemaining = dso.itemCount - dso.itemRunningTotal;
					dso.itemPercentage = (100 * dso.itemRunningTotal) / dso.itemCount;
				}
				dateShiftFinished = dateShiftFinished && dso.itemShiftFinished;
				dateShiftHadErrors = dateShiftHadErrors || dso.itemNumberOfErrors > 0;
			} catch (err) {
				console.log(`in forEach: error: ${err.message}`);
			}
		};
		component.dateShiftFinished = dateShiftFinished;
		component.dateShiftHadErrors = dateShiftHadErrors;
		if (dateShiftFinished) {
			unsubscribe(component.subscription, (result) => {
				console.log("Batch event unsubscribed.");
				component.subscription = null;
			});
			if (dateShiftHadErrors)
				component.dispatchEvent(
					new showToastEvent({
						mode: "sticky",
						variant: "error",
						message: "Errors occurred during the date shift. Please check the system debug log for details.\n" + "All records without errors were date shifted correctly."
					})
				);
			component.dispatchEvent(
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
