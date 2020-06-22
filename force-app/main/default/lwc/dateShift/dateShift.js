import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class DateShift extends NavigationMixin(LightningElement) {

	helpSectionVisible = false;

	handleDateShiftObjectClick() {
		this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName : 'Date_Shift_Object__c',
				actionName : 'home'
			}
        });
	}
}