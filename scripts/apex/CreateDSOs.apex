//  Creates the date shift objects necessary to test the Demo Date Shifter

insert new Date_Shift_Object__c (
    Active__c = true,
    Object_API_Name__c = 'Task',
    Weekdays_Only__c = true,
    Adjust_Minutes__c = false
);

insert new Date_Shift_Object__c (
    Active__c = true,
    Object_API_Name__c = 'Event',
    Weekdays_Only__c = false,
    Adjust_Minutes__c = true
);