import { LightningElement, wire, track, api } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import { subscribe, unsubscribe } from "lightning/empApi";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getObjectItems from "@salesforce/apex/DemoDateShifter.getObjectItems";
import dateShift from "@salesforce/apex/DemoDateShifter.dateShift";

export default class DateShift extends NavigationMixin(LightningElement) {
	objectListColumns = [
		{ label: "Records", fieldName: "itemCount", type: "number", initialWidth: 100, cellAttributes: { alignment: "right" } },
		{
			label: "Weekdays Only",
			fieldName: "itemWeekdaysOnly",
			type: "boolean",
			initialWidth: 120,
			cellAttributes: { alignment: "center" }
		},
		{
			label: "Adjust Minutes",
			fieldName: "itemAdjustMinutes",
			type: "boolean",
			initialWidth: 120,
			cellAttributes: { alignment: "center" }
		},
		{
			label: "Object",
			fieldName: "itemLink",
			type: "url",
			cellAttributes: { iconName: "standard:shift", alignment: "left" },
			typeAttributes: { label: { fieldName: "itemLabel" }, tooltip: { fieldName: "itemLabelPlural" }, target: "_parent" }
		}
	];
	errorListColumns = [
		{
			label: "Record",
			fieldName: "link",
			type: "url",
			initialWidth: 200,
			iconName: "standard:record",
			cellAttributes: { alignment: "left" },
			typeAttributes: { label: { fieldName: "name" }, target: "_parent" }
		},
		{
			label: "Problem Fields",
			fieldName: "fields",
			type: "text",
			iconName: "standard:first_non_empty",
			initialWidth: 200,
			cellAttributes: { alignment: "left" }
		},
		{
			label: "Error Message",
			fieldName: "message",
			type: "text",
			iconName: "standard:live_chat",
			wrapText: true,
			cellAttributes: { alignment: "left" }
		}
	];

	@api cardTitle = "Demo Date Shifter";

	@track objectList = [];
	@track errorList = [];
	objectListIsEmpty = true;
	maxDateShiftObjects = 45;
	get tooManyObjects() {
		return this.objectList.length > this.maxDateShiftObjects;
	}

	returnedMinutes = 0;
	returnedDays = 0;
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

	dateShiftObjectListViewURL = "";
	dateShiftObjectListViewSpec = {
		type: "standard__objectPage",
		attributes: {
			objectApiName: "Date_Shift_Object__c",
			actionName: "list"
		},
		state: {
			filterName: "All"
		}
	};

	error;

	connectedCallback() {
		this[NavigationMixin.GenerateUrl](this.dateShiftObjectListViewSpec).then((url) => {
			this.dateShiftObjectListViewURL = url;
		});
	}

	@wire(getObjectItems)
	wired_getObjectItems({ data, error }) {
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
					itemToolTip: dso.itemToolTip,
					itemShiftFinished: dso.itemShiftFinished
				});
			});
			this.objectListIsEmpty = this.objectList.length === 0;
		} else if (error) {
			this.showErrorToast(error, "Could not get the list of object items");
		}
	}

	handleDateShiftObjectClick(event) {
		event.preventDefault();
		event.stopPropagation();
		this[NavigationMixin.Navigate](this.dateShiftObjectListViewSpec);
	}

	handleShiftDatesButton() {
		this.startingDateShift = true;
		dateShift({ minutesToShift: this.returnedMinutes, daysToShift: this.returnedDays })
			.then(() => {
				subscribe("/event/Date_Shift_Event__e", -1, this.handleBatchEvent.bind(this)).then((result) => {
					this.subscription = result;
				});
				this.shiftInProgress = true;
			})
			.catch((error) => {
				this.showErrorToast(error, "Could not shift the dates in the org");
			});
		this.startingDateShift = false;
	}

	handleHelpButton() {
		this.helpSectionVisible = !this.helpSectionVisible;
	}

	handleDateFilterChange(event) {
		this.dateFilterNotSet = !event.detail.isSet;
		this.returnedMinutes = event.detail.returnedMinutes;
		this.returnedDays = event.detail.returnedDays;
		this.minutesToShift = event.detail.minutesToShift;
		this.daysToShift = event.detail.daysToShift;
		this.forBack = event.detail.forBack;
		this.objectApiName = event.detail.objectApiName;
		this.fieldApiName = event.detail.fieldApiName;
		this.dateOfDemo = event.detail.dateOfDemo;
	}

	handleBatchEvent(event) {
		let dateShiftFinished = true;
		let dateShiftHadErrors = false;
		this.objectList.forEach((dso) => {
			if (dso.itemAPIName === event.data.payload.SObject_API_Name__c) {
				dso.itemRunningTotal = event.data.payload.Running_Total__c;
				dso.itemNumberOfErrors = event.data.payload.Errors__c;
				dso.itemShiftFinished = dso.itemRunningTotal >= dso.itemCount;
				dso.itemRemaining = dso.itemCount - dso.itemRunningTotal;
				dso.itemPercentage = Math.round((100 * dso.itemRunningTotal) / dso.itemCount);
				dso.itemToolTip = `Completed ${dso.itemRunningTotal} / ${dso.itemCount} (${dso.itemPercentage}%)`;
			}
			dateShiftFinished = dateShiftFinished && dso.itemShiftFinished;
			dateShiftHadErrors = dateShiftHadErrors || dso.itemNumberOfErrors > 0;
		});
		this.dateShiftFinished = dateShiftFinished;
		this.dateShiftHadErrors = dateShiftHadErrors;
		JSON.parse(event.data.payload.Error_List__c).forEach((error) => {
			this.errorList.push(error);
		});
		if (dateShiftFinished) {
			unsubscribe(this.subscription, (result) => {
				this.subscription = {};
			});
			this.dispatchEvent(
				new ShowToastEvent({
					mode: "sticky",
					variant: "info",
					title: `Dates were shifted ${this.forBack} by ${this.minutesToShift} minutes (${this.daysToShift} days).`,
					message:
						"Make sure that you run any Einstein Analytics dataflows that contain the records you shifted so that your dashboards will reflect the shifted dates."
				})
			);
		}
	}

	showErrorToast(error, title) {
		this.error = "Unknown error";
		if (Array.isArray(error.body)) this.error = error.body.map((err) => err.message).join(", ");
		else if (typeof error.body.message === "string") this.error = error.body.message;
		this.dispatchEvent(
			new ShowToastEvent({
				mode: "sticky",
				variant: "error",
				title: title,
				message: this.error
			})
		);
	}
}
