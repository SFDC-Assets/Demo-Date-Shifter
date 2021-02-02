//  Javascript controller for the Demo Date Shifter component.
//
//  This code is provided AS IS, with no warranty or guarantee of suitability for use.
//  Contact: john.meyer@salesforce.com

import { LightningElement, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getCustomDateShifterSettings from '@salesforce/apex/DemoDateShifter.getCustomDateShifterSettings';
import setCustomDateShifterSettings from '@salesforce/apex/DemoDateShifter.setCustomDateShifterSettings';
import deleteCustomDateShifterSettings from '@salesforce/apex/DemoDateShifter.deleteCustomDateShifterSettings';
import getOrgObjectList from '@salesforce/apex/DemoDateShifter.getOrgObjectList';
import getDateTimeFields from '@salesforce/apex/DemoDateShifter.getDateTimeFields';
import getMinutesToShift from '@salesforce/apex/DemoDateShifter.getMinutesToShift';

export default class DateShiftDateSelector extends LightningElement {
	shiftOptions = [
		{
			label: 'By basing it off of a most recent record',
			value: 'byData'
		},
		{
			label: 'By explicitly specifying the amount of time',
			value: 'byMinute'
		}
	];
	howToShift = 'byData';
	get shiftByMinutes() {
		return this.howToShift === 'byMinute';
	}
	daysInput = 0;
	hoursInput = 0;
	minutesInput = 0;
	get shiftByReference() {
		return this.howToShift === 'byData';
	}
	forwardBackwardOptions = [
		{
			label: 'Shift Dates Forward',
			value: 'forward'
		},
		{
			label: 'Shift Dates Backward',
			value: 'backward'
		}
	];

	@track orgObjectList = [];
	objectApiName = '';
	get objectSelectorDisabled() {
		return this.savedSettingsFound;
	}

	@track fieldList = [];
	fieldApiName = '';
	get fieldSelectorDisabled() {
		return this.savedSettingsFound || this.objectApiName === '';
	}

	get saveSelectionToggleDisabled() {
		return this.objectApiName === '' || this.fieldApiName === '';
	}

	savedSettingsFound = false;
	get showSaveSettingsButton() {
		return !this.savedSettingsFound;
	}
	get saveSettingsButtonDisabled() {
		return this.objectApiName === '' || this.fieldApiName === '';
	}

	dateOfDemo = new Date(Date.now()).toISOString();
	dateOfDemoSelected = false;
	mostRecent = '';

	loading = true;

	validQuery = false;
	returnedMinutes = 0;
	returnedDays = 0;
	minutesToShift = 0;
	daysToShift = 0;
	forBack = 'forward';

	get shiftAmountVisible() {
		return this.shiftByReference
			? this.objectApiName !== '' && this.fieldApiName !== '' && this.dateOfDemoSelected && this.validQuery
			: this.minutesToShift !== 0;
	}

	@wire(getOrgObjectList)
	wired_getOrgObjectList({ data, error }) {
		this.orgObjectList = [];
		if (data) {
			data.forEach((object) => {
				this.orgObjectList.push({
					value: object.apiName,
					label: object.label
				});
			});
			this.orgObjectList
				.sort((a, b) => (a.label > b.label ? 1 : -1))
				.unshift({
					value: '',
					label: 'Select an object'
				});
			getCustomDateShifterSettings()
				.then((result) => {
					if (result.settingsFound) {
						if (result.objectApiNameIsValid) {
							if (result.fieldApiNameIsValid) {
								this.objectApiName = result.objectApiName;
								this.fieldApiName = result.fieldApiName;
								this.savedSettingsFound = true;
							} else {
								this.dispatchEvent(
									new ShowToastEvent({
										mode: 'sticky',
										variant: 'error',
										message: `The custom setting "Date_Shifter_Saved_Settings__c" for your profile has an incorrect "Field_API_Name__c" value ("${result.fieldApiName}"). Please correct it or delete it to remove this message.`
									})
								);
								this.fieldApiName = '';
							}
						} else {
							this.dispatchEvent(
								new ShowToastEvent({
									mode: 'sticky',
									variant: 'error',
									message: `The custom setting "Date_Shifter_Saved_Settings__c" for your profile has an incorrect "Object_API_Name__c" value ("${result.objectApiName}"). Please correct it or delete it to remove this message.`
								})
							);
							this.fieldApiName = '';
							this.objectApiName = '';
						}
					} else this.fieldApiName = '';
				})
				.catch((error) => {
					this.showErrorToast(error, 'Could not retrieve saved selections');
				});
			this.loading = false;
		} else if (error) this.showErrorToast(error, 'Could not get a list of objects in the org');
	}

	@wire(getDateTimeFields, { objectApiName: '$objectApiName' })
	wired_getGetDateTimeFields({ data, error }) {
		this.fieldList = [];
		if (data) {
			data.forEach((field) => {
				this.fieldList.push({
					value: field.apiName,
					label: field.label
				});
			});
			if (this.fieldList.length === 0)
				this.fieldList.push({
					value: '',
					label: `${this.objectApiName} object has no updateable DateTime fields`
				});
			else
				this.fieldList
					.sort((a, b) => (a.label > b.label ? 1 : -1))
					.unshift({
						value: '',
						label: 'Select a field'
					});
		} else if (error)
			this.showErrorToast(error, `Could not get the Date and DateTime fields for the ${this.objectApiName} object`);
	}

	handleHowToShift(event) {
		this.howToShift = event.target.value;
		this.notifyParent(false);
	}

	handleDaysInput(event) {
		this.daysInput = Math.abs(parseInt(event.target.value, 10));
		this.calculateShift();
	}

	handleHoursInput(event) {
		this.hoursInput = Math.abs(parseInt(event.target.value, 10));
		this.calculateShift();
	}

	handleMinutesInput(event) {
		this.minutesInput = Math.abs(parseInt(event.target.value, 10));
		this.calculateShift();
	}

	handleForwardBackwardInput(event) {
		this.forBack = event.target.value === 'forward' ? 'forward' : 'backward';
		this.calculateShift();
	}

	handleObjectChange(event) {
		this.objectApiName = event.target.value;
		this.fieldApiName = '';
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

	handleSaveSettingsButton(event) {
		if (event.detail.checked) {
			setCustomDateShifterSettings({ objectApiName: this.objectApiName, fieldApiName: this.fieldApiName })
				.then(() => {
					this.dispatchEvent(
						new ShowToastEvent({
							variant: 'success',
							message: 'Your selections have been saved.'
						})
					);
					this.savedSettingsFound = true;
				})
				.catch((error) => {
					this.showErrorToast(error, 'Could not save selections');
				});
		} else {
			deleteCustomDateShifterSettings()
				.then(() => {
					this.dispatchEvent(
						new ShowToastEvent({
							variant: 'success',
							message: 'Your saved selections have been removed.'
						})
					);
					this.savedSettingsFound = false;
				})
				.catch((error) => {
					this.showErrorToast(error, 'Could not remove saved selections');
				});
		}
	}

	calculateShift() {
		switch (this.howToShift) {
			case 'byMinute':
				this.minutesToShift = this.daysInput * 24 * 60 + this.hoursInput * 60 + this.minutesInput;
				this.returnedMinutes = this.minutesToShift * (this.forBack === 'backward' ? -1 : 1);
				this.daysToShift = Math.round(this.minutesToShift / 60 / 24);
				this.returnedDays = this.daysToShift * (this.forBack === 'backward' ? -1 : 1);
				this.validQuery = true;
				this.notifyParent(this.minutesToShift !== 0);
				break;
			case 'byData':
				if (this.fieldApiName !== '' && this.dateOfDemoSelected) {
					getMinutesToShift({
						dateOfDemo: this.dateOfDemo,
						objectApiName: this.objectApiName,
						fieldApiName: this.fieldApiName
					})
						.then((result) => {
							this.validQuery = result.validQuery;
							if (result.validQuery) {
								this.mostRecent = result.mostRecent;
								this.returnedMinutes = result.minutes;
								this.returnedDays = Math.round(this.returnedMinutes / 60 / 24);
								this.minutesToShift = Math.abs(this.returnedMinutes);
								this.daysToShift = Math.round(Math.abs(this.returnedMinutes) / 60 / 24);
								this.forBack = this.returnedMinutes < 0 ? 'backward' : 'forward';
								this.notifyParent(this.shiftAmountVisible);
							} else {
								this.dispatchEvent(
									new ShowToastEvent({
										mode: 'sticky',
										variant: 'error',
										message: `Could not find any "${this.objectApiName}" records with a non-empty "${this.fieldApiName}" field value.`
									})
								);
							}
						})
						.catch((error) => {
							this.showErrorToast(error, 'Could not calculate the time shift');
						});
				}
				break;
		}
	}

	notifyParent(isSet) {
		this.dispatchEvent(
			new CustomEvent('datefilterchange', {
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

	showErrorToast(error, title) {
		this.error = 'Unknown error';
		if (Array.isArray(error.body)) this.error = error.body.map((err) => err.message).join(', ');
		else if (typeof error.body.message === 'string') this.error = error.body.message;
		this.dispatchEvent(
			new ShowToastEvent({
				mode: 'sticky',
				variant: 'error',
				title: title,
				message: this.error
			})
		);
	}
}
