//  Controller for the DemoDateShifter Lightning component.
//
//  This code is provided AS IS, with no warranty or guarantee of suitability for use.
//  Contact: john.meyer@salesforce.com

public with sharing class DemoDateShifter {
 
    public class Toast {
        @AuraEnabled public String toastMessage;
        @AuraEnabled public String toastVariant;
        @AuraEnabled public String toastMode;
    }
    
    public class ObjectItem {
        @AuraEnabled public Id itemId;
        @AuraEnabled public String itemAPIName;
        @AuraEnabled public String itemLabel;
        @AuraEnabled public String itemLabelPlural;
        @AuraEnabled public Boolean itemWeekdaysOnly;
        @AuraEnabled public Boolean itemAdjustMinutes;
        @AuraEnabled public String itemLink;
        @AuraEnabled public Integer itemCount;
        @AuraEnabled public Integer itemRunningTotal;
        @AuraEnabled public Integer itemNumberOfErrors;
        @AuraEnabled public Boolean itemShiftFinished;
    }

    public class Selector {
        @AuraEnabled public String label;
        @AuraEnabled public String apiName;
    }

    
    //  Get the list of objects in the org.

    @AuraEnabled(cacheable=true)
    public static List<Selector> getOrgObjectList () {
        List<Selector> osList = new List<Selector>();
        for (Schema.SObjectType sot : Schema.getGlobalDescribe().values()) {
            Schema.DescribeSObjectResult dsor = sot.getDescribe();
            Selector s = new Selector();
            String apiName = dsor.getName();
            if (dsor.isUpdateable()) {
                s.apiName = apiName;
                s.label = dsor.getLabel();
                osList.add(s);
            }
        }
        return osList;
    }

    //  Get the list of DateTime fields in the given object

    @AuraEnabled(cacheable=true)
    public static List<Selector> getDateTimeFields (String objectApiName) {
        List<Selector> fieldList = new List<Selector>();
        if (objectApiName != '') {
            Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get(objectAPIName).getDescribe().fields.getMap();         
            for (String fieldName : fieldMap.keySet()) {
                Schema.DescribeFieldResult dfr = fieldMap.get(fieldName).getDescribe();
                Selector s = new Selector();
                if (dfr.isUpdateable() && (dfr.getType().name() == 'Date' || dfr.getType().name() == 'DateTime')) {
                    s.apiName = dfr.getName();
                    s.label = dfr.getLabel();
                    fieldList.add(s);
                }
            }
        }
        return fieldList;
    }

        
    //  Get the list of the date shift objects to put into the list on the Lightning component.
        
    @AuraEnabled
    public static List<ObjectItem> getObjectItems () {
        List<ObjectItem> objectItems = new List<ObjectItem>();        
        List<Date_Shift_Object__c> dateShiftObjects = [SELECT Object_API_Name__c FROM Date_Shift_Object__c WHERE Active__c = true ORDER BY Object_API_Name__c ASC];
        for (Date_Shift_Object__c dso : dateShiftObjects) {
            ObjectItem item = getObjectItem(dso.Object_API_Name__c);
            if (item != null)
                objectItems.add(item);
        }        
        return objectItems;
    }
    
    
    //  Calculate the number of minutes to shift for displaying on the Lightning component.
    
    @AuraEnabled
    public static Integer getMinutesToShift (String dateOfDemo, String objectApiName, String fieldApiName) {
        if (dateOfDemo != '' && objectApiName != '' && fieldApiName != '') {
            dateOfDemo = dateOfDemo.substring(0,4) + '-' + dateOfDemo.substring(5,7) + '-' + dateOfDemo.substring(8,10) + ' ' + dateOfDemo.substring(11,13) + ':' + dateOfDemo.substring(14,16) + ':' + dateOfDemo.substring(17,19);
            sObject record = Database.query('SELECT ' + fieldApiName + ' FROM ' + objectApiName + ' WHERE ' + fieldApiName + ' != null ORDER BY ' + fieldApiName + ' DESC LIMIT 1');
            return record == null ? 0 : (Integer) (Math.round((Decimal) (DateTime.valueOfGMT(dateOfDemo).getTime() - ((DateTime) record.get(fieldApiName)).getTime()) / 1000.0 / 60.0));
        } else {
            return 0;
        }
    }
    
    
    //  Shift the Date and DateTime fields of records based on the criteria specified.
    
    @AuraEnabled
    public static List<Toast> dateShift (String dateOfDemo, String objectApiName, String fieldApiName) {
        
        List<Toast> toasts = new List<Toast>();        
        
        DateTime demoDate = DateTime.valueOfGMT(dateOfDemo);
        
        // Figure out what record we want to base the date and time off of.
        
        sObject record = Database.query('SELECT ' + fieldApiName + ' FROM ' + objectApiName + ' WHERE ' + fieldApiName + ' != null ORDER BY ' + fieldApiName + ' DESC LIMIT 1');
        
        if (record == null) {
	        Toast toast = new Toast();
            toast.toastMessage = 'Could not find any ' + Schema.getGlobalDescribe().get(objectApiName).getDescribe().getLabel().toLowerCase() + ' records in the org from which to to base the last day.';
            toast.toastVariant = 'error';
            toast.toastMode = 'sticky';
            toasts.add(toast);
        } else {
            Integer minutesToShift = (Integer) (Math.round((Decimal) (DateTime.valueOfGMT(dateOfDemo).getTime() - ((DateTime) record.get(fieldApiName)).getTime()) / 1000.0 / 60.0));
            Integer daysToShift = (Integer) Math.round(((Decimal) minutesToShift) / 60.0 / 24.0);
            if (minutesToShift == 0) {
                Toast toast = new Toast();
                toast.toastMessage = 'The given date and time is already the same as the specified date and time.';
                toast.toastVariant = 'info';
                toast.toastMode = 'dismissable';
                toasts.add(toast);
            } else
                for (ObjectItem item : getObjectItems ()) {
                    Toast toast = shiftDatesAsynchronously(minutesToShift, daysToShift, item.itemAPIName, getDateFieldNames(item.itemAPIName), item.itemWeekdaysOnly, item.itemAdjustMinutes);
                    if (toast != null)
                        toasts.add(toast);
                }
        }
        
        return toasts;
    }
    
    
    //  Shift the dates (forward or backward) in the Date or DateTime fields of the given object by the specified amount.  This operation is
    //  done asynchronously, so a larger number of records can be updated.  It executes in the background, and an email is sent to the user
    //  when it is finished.
    //  
    //  The parameters represent:
    //      minutesToAdd: the number of minutes to add to the DateTimes (can be negative to shift dates backward).)
    //      daysToAdd: the number of days to add (can be negative to shift dates backward).
    //      sObjectAPIName: the API name of the object whose records are to be deleted.
    //      fieldList: a list of the API names of the Date or DateTime fields to be shifted.
    //      weekdaysOnly: if true, an additional shift will ensure that the date falls on a weekday.
    //      adjustMinutes: if true, adjust the minutes; otherwise just adjust to the nearest day.
    
    private static Toast shiftDatesAsynchronously (Integer minutesToAdd, Integer daysToAdd, String sObjectAPIName, List<String> fieldList, Boolean weekdaysOnly, Boolean adjustMinutes) {
        
        Toast toast = null;
        
        String forback = minutesToAdd > 0 ? 'forward' : 'backward';        
        String sObjectLabel = Schema.getGlobalDescribe().get(sObjectAPIName).getDescribe().getLabel().toLowerCase();
        
        if (fieldList.IsEmpty()) {
            toast = new Toast();
            toast.toastMessage = sObjectLabel.capitalize() + 's do not have any Date or DateTime fields.';
            toast.toastVariant = 'error';
            toast.toastMode = 'sticky';
        } else
            Database.executeBatch(new DemoDateShifterBatch(minutesToAdd, daystoAdd, sObjectAPIName, fieldList, weekdaysOnly, adjustMinutes));
        
        return toast;
    }
    
    
    //  Utility to return an ObjectItem given an sObject API name.  Not the most efficient way of doing things, but hopefully there
    //  are just a few objects in the org that need their dates shifted.
    
    private static ObjectItem getObjectItem (String sObjectAPIName) {
        
        Date_Shift_Object__c dso = [SELECT Object_API_Name__c, Weekdays_Only__c, Adjust_Minutes__c FROM Date_Shift_Object__c WHERE Active__c = true AND Object_API_Name__c = :sObjectAPIName LIMIT 1];
        
        if (dso == null)
            return null;
        else {
            ObjectItem item = new ObjectItem();
            item.itemId = dso.Id;
            item.itemAPIName = dso.Object_API_Name__c;
            item.itemLabel = Schema.getGlobalDescribe().get(dso.Object_API_Name__c).getDescribe().getLabel();
            item.itemLabelPlural = Schema.getGlobalDescribe().get(dso.Object_API_Name__c).getDescribe().getLabelPlural();
            item.itemWeekdaysOnly = dso.Weekdays_Only__c;
            item.itemAdjustMinutes = dso.Adjust_Minutes__c;
            item.itemLink = '/lightning/r/' + dso.Id + '/view';
            try {
                item.itemCount = Database.countQuery('SELECT count() FROM ' + dso.Object_API_Name__c);
            } catch (QueryException e) {
                System.debug('Date shift problem getting object item count: ' + e.getMessage());
                item.itemCount = 0;
            }
            item.itemRunningTotal = 0;
            item.itemNumberOfErrors = 0;
            item.itemShiftFinished = false;
            return item;
        }
    }
    
    
    //  Utility to get all of the updateable Date and DateTime field API names from the given object.
    
    private static List<String> getDateFieldNames (String sObjectAPIName) {
        
        try {
            Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get(sObjectAPIName).getDescribe().fields.getMap();         
            Set<String> dateFieldNames = new Set<String>();
            for (String fieldName : fieldMap.keySet()) {
                Schema.DescribeFieldResult dfr = fieldMap.get(fieldName).getDescribe();
                if (dfr.isUpdateable() && (dfr.getType().name() == 'Date' || dfr.getType().name() == 'DateTime'))
                    dateFieldNames.add(dfr.getName());
            }
            dateFieldNames.removeAll(new List<String> {'SlaStartDate', 'SlaExitDate'});			//  Special case: never return these
            return new List<String>(dateFieldNames);
        } catch (Exception e) {
            System.debug('getDateFieldName: ' + e.getMessage());
            return null;
        }        
    }    
}
