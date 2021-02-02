//  Batch date update methods for the DemoShiftDates Lightning component.
//
//  This code is provided AS IS, with no warranty or guarantee of suitability for use.
//  Contact: john.meyer@salesforce.com


global without sharing class DemoDateShifterBatch implements Database.Batchable<sObject>, Database.Stateful, Database.RaisesPlatformEvents {
    
    private Integer minutesToAdd = 0;
    private Integer daysToAdd = 0;
    private String sObjectApiName;
    private String sObjectLabel;
    private String nameField;
    private List<String> fieldList;
    private Boolean weekdaysOnly;
    private Boolean adjustMinutes;

    private Integer totalRecordsProcessed = 0;   
    private Integer totalErrors = 0; 


    //  Class used to collect error information to send back to the component.

	private class ErrorSpec {
		private Id id;
		private String name;
		private String link;
		private String fields;
		private String message;
	}
   
    
    //  Constructor method that gathers the information for the batch job and builds the query string.
    //  
    //  The parameters represent:
    //      minutesToadd:  the number of minutes to add to the DateTime fields; can be negative to shift dates backward.
    //      daysToAdd:  the number of days to add to the Date fields; can be negative to shift dates backward.
    //      sObjectApiName:  the API name of the object whose fields we will shift.
    //      fieldList:  a list of the API names of the Date or DateTime fields we will update.
    //      weekdaysOnly:  true if the date on a particular record should always fall on a weekday.
    //      adjustMinutes:  true if the adjusted date should adjust the minutes as well.
    
    global DemoDateShifterBatch (Integer minutesToAdd, Integer daysToAdd, String sObjectApiName, List<String> fieldList, Boolean weekdaysOnly, Boolean adjustMinutes) {
        this.minutesToAdd = minutesToAdd;
        this.daysToAdd = daysToAdd;
        this.sObjectApiName = sObjectApiName;
        this.sObjectLabel = Schema.getGlobalDescribe().get(sObjectApiName).getDescribe().getLabel();
        this.nameField = getNameField(sObjectApiName);
        this.fieldList = fieldList;
        this.weekdaysOnly = weekdaysOnly;
        this.adjustMinutes = adjustMinutes;
    }
    
    
    //  Start the query.
    
    global Database.QueryLocator start (Database.BatchableContext bc) {
        return Database.getQueryLocator('SELECT ' + this.nameField + ',' + String.join(this.fieldList, ',') + ' FROM ' + this.sObjectApiName);
    }
    
    
    //  With each batch of records, cycle through the Date or DateTime field names and update them.
    
    global void execute (Database.BatchableContext bc, List<sObject> chunk) {
        
        for (sObject so : chunk)
            for (String field : this.fieldList)
                if (so.get(field) != null) {
                    if (so.get(field) instanceof Date) {
                        Date dateField = (Date) so.get(field);
                        dateField = dateField.addDays(daysToAdd);
                        if (this.weekdaysOnly)
                            dateField = updateDateNoWeekends(dateField);
                        so.put(field, dateField);
                    } else if (so.get(field) instanceof DateTime) {
                        DateTime dateTimeField = (DateTime) so.get(field);
                        if (this.adjustMinutes)
                            dateTimeField = dateTimeField.addMinutes(this.minutesToAdd);
                        else
                            dateTimeField = dateTimeField.addDays(this.daysToAdd);
                        if (this.weekdaysOnly)
                            dateTimeField = updateDateTimeNoWeekends(dateTimeField);
                        so.put(field, dateTimeField);
                    }
                }


        List<ErrorSpec> errors = new List<ErrorSpec>();
        Integer recordNumber = 0;

        for (Database.SaveResult result : Database.update(chunk, false)) {
            if (!result.isSuccess())
                for (Database.Error dberror : result.getErrors()) {
                    ErrorSpec error = new ErrorSpec();
                    Id id = result.getId();
                    error.id = id;
                    error.name = String.valueOf(chunk[recordNumber].get(this.nameField));
                    error.link = '/lightning/r/' + this.sObjectApiName + '/' + id + '/view';
                    error.fields = String.join(dberror.getFields(), ', ');
                    error.message = dberror.getMessage();
                    errors.add(error);
                }
            recordNumber++;
        }

        this.totalRecordsProcessed += chunk.size();
        this.totalErrors += errors.size();

        
        EventBus.publish (new Date_Shift_Event__e (
            SObject_API_Name__c = this.sObjectApiName,
            Running_Total__c = this.totalRecordsProcessed,
            Errors__c = this.totalErrors,
            Error_List__c = JSON.serialize(errors),
            Finished__c = false
        ));
    }
    
    
    global void finish (Database.BatchableContext bc) {        
        EventBus.publish (new Date_Shift_Event__e (
            SObject_API_Name__c = this.sObjectApiName,
            Running_Total__c = this.totalRecordsProcessed,
            Errors__c = this.totalErrors,
            Error_List__c = '[]',
            Finished__c = true
        ));
    }
 

    //  Find the name field for an object.

    private static String getNameField (String objectApiName) {
        String name = '';
        for (Schema.SObjectField field : Schema.getGlobalDescribe().get(objectApiName).getDescribe().fields.getMap().values())
            if (field.getDescribe().isNameField()) {
                name = field.getDescribe().getName();
                break;
            }
        return name;
    }
   
    
    //  Utilities to adjust a date to make sure that it does not fall on a weekend.  If the given date falls on a Saturday, it is updated
    //  to fall on the previous Friday; if it falls on a Sunday, it is updated to fall on the following Monday.
    
    private static DateTime updateDateTimeNoWeekends (DateTime theDate) {
        
        String startFormat = theDate.format('u');
        
        if (startFormat.contains('6'))
            return theDate.addDays(-1);
        else if (startFormat.contains('7'))
            return theDate.addDays(1);
        else
            return theDate;       
    }
    
    private static Date updateDateNoWeekends (Date theDate) {
        
        String startFormat = DateTime.valueOf(theDate.year() + '-' + theDate.month() + '-' + theDate.day() + ' 01:00:00').format('u');
        
        if (startFormat.contains('6'))
            return theDate.addDays(-1);
        else if (startFormat.contains('7'))
            return theDate.addDays(1);
        else
            return theDate;               
    }

}
