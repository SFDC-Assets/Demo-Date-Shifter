//  Batch date update methods for the DemoShiftDates Lightning component.
//
//  This code is provided AS IS, with no warranty or guarantee of suitability for use.
//  Contact: john.meyer@salesforce.com


global with sharing class DemoDateShifterBatch implements Database.Batchable<sObject>, Database.Stateful, Database.RaisesPlatformEvents {
    
    private Integer minutesToAdd = 0;
    private Integer daysToAdd = 0;
    private String sObjectAPIName;
    private String sObjectLabel;
    private List<String> fieldList;
    private Boolean weekdaysOnly;
    private Boolean adjustMinutes;

    private Integer totalRecordsProcessed = 0;   
    private Integer totalErrors = 0;
    
    
    //  Constructor method that gathers the information for the batch job and builds the query string.
    //  
    //  The parameters represent:
    //      additionalMinutes:  the number of minutes to add to the DateTime fields; can be negative to shift dates backward.
    //      additionalDays:  the number of days to add to the Date fields; can be negative to shift dates backward.
    //      objectAPIName:  the API name of the object whose fields we will shift.
    //      fields:  a list of the API names of the Date or DateTime fields we will update.
    //      weekdays:  true if the date on a particular record should always fall on a weekday.
    //      minutes:  true if the adjusted date should adjust the minutes as well.
    
    global DemoDateShifterBatch (Integer additionalMinutes, Integer additionalDays, String objectAPIName, List<String> fields, Boolean weekdays, Boolean minutes) {
        minutesToAdd = additionalMinutes;
        daysToAdd = additionalDays;
        sObjectAPIName = objectAPIName;
        sObjectLabel = Schema.getGlobalDescribe().get(objectAPIName).getDescribe().getLabel();
        fieldList = fields;
        weekdaysOnly = weekdays;
        adjustMinutes = minutes;
    }
    
    
    //  Start the query.
    
    global Database.QueryLocator start (Database.BatchableContext bc) {
        return Database.getQueryLocator('SELECT ' + String.join(fieldList, ',') + ' FROM ' + sObjectAPIName);
    }
    
    
    //  With each batch of records, cycle through the Date or DateTime field names and update them.
    
    global void execute (Database.BatchableContext bc, List<sObject> scope) {
        
        for (sObject so : scope) {
            for (String field : fieldList) {
                if (so.get(field) != null) {
                    if (so.get(field) instanceof Date) {
                        Date dateField = (Date) so.get(field);
                        dateField = dateField.addDays(daysToAdd);
                        if (weekdaysOnly)
                            dateField = updateDateNoWeekends(dateField);
                        so.put(field, dateField);
                    } else if (so.get(field) instanceof DateTime) {
                        DateTime dateTimeField = (DateTime) so.get(field);
                        if (adjustMinutes)
                            dateTimeField = dateTimeField.addMinutes(minutesToAdd);
                        else
                            dateTimeField = dateTimeField.addDays(daysToAdd);
                        if (weekdaysOnly)
                            dateTimeField = updateDateTimeNoWeekends(dateTimeField);
                        so.put(field, dateTimeField);
                    }
                }
            }
        }

        Integer index = 0;
        String errorJSON = '';
        for (Database.SaveResult result : Database.update(scope, false)) {
            if (!result.isSuccess())
                for (Database.Error error : result.getErrors()) {
                    String id = (String) scope.get(index).get('Id');
                    errorJSON += '{"id":"' + id + '","name":"' + sObjectLabel + '","link":"' + URL.getSalesforceBaseUrl().toExternalForm() + '/' + id +
                    '","fields":"' + String.join(error.getFields(),',') + '","message":"' + error.getMessage().escapeEcmaScript() + '"},';
                    totalErrors++;
                }
            index++;
        }
        errorJSON = '[' + errorJSON.substringBeforeLast(',') + ']';   // Remove final ',' from error list
       
        totalRecordsProcessed += scope.size();
        
        Database.SaveResult eventResult = EventBus.publish (new Date_Shift_Event__e (
            SObject_API_Name__c = sObjectAPIName,
            Running_Total__c = totalRecordsProcessed,
            Errors__c = totalErrors,
            Error_List__c = errorJSON
        ));
        if (!eventResult.isSuccess())
            for (Database.Error error : eventResult.getErrors())
                System.debug('Date shift could not publish event: ' + error.getMessage());
    }
    
    
    global void finish (Database.BatchableContext bc) {        
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
