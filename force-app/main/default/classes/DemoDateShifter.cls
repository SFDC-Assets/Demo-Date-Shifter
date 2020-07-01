//  Controller for the DemoDateShifter Lightning component.
//
//  This code is provided AS IS, with no warranty or guarantee of suitability for use.
//  Contact: john.meyer@salesforce.com

public without sharing class DemoDateShifter {
 
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
        @AuraEnabled public Integer itemRemaining;
        @AuraEnabled public Integer itemPercentage;
        @AuraEnabled public String itemToolTip;
        @AuraEnabled public Boolean itemShiftFinished;
    }

    public class Selector {
        @AuraEnabled public String label;
        @AuraEnabled public String apiName;
    }

    public class DateDifference {
        @AuraEnabled public DateTime mostRecent;
        @AuraEnabled public Integer minutes;
    }

    public class DateShifterSettings {
        @AuraEnabled public Boolean settingsFound;
        @AuraEnabled public String objectApiName;
        @AuraEnabled public Boolean objectApiNameIsValid;
        @AuraEnabled public String fieldApiName;
        @AuraEnabled public Boolean fieldApiNameIsValid;
    }


    //  Get the custome settings for the object and field API names, if they exist in the org.

    @AuraEnabled(cacheable=true)
    public static DateShifterSettings getCustomDateShifterSettings () {
        Date_Shifter_Saved_Settings__c s = Date_Shifter_Saved_Settings__c.getInstance();
        DateShifterSettings dssettings = new DateShifterSettings();
        if (s.Object_API_Name__c == null) {
            dssettings.settingsFound = false;
            dssettings.objectApiNameIsValid = false;
            dssettings.fieldApiNameIsValid = false;
        } else {
            dssettings.settingsFound = true;
            dssettings.objectApiName = s.Object_API_Name__c;
            dssettings.fieldApiName = s.Field_API_Name__c;
            Schema.SObjectType sot = Schema.getGlobalDescribe().get(s.Object_API_Name__c);
            if (sot == null)
                dssettings.objectApiNameIsValid = false;
            else {
                dssettings.objectApiNameIsValid = true;
                dssettings.fieldApiNameIsValid = sot.getDescribe().fields.getMap().get(s.Field_API_Name__c) != null;
            }
        }
        return dssettings;
    }
    
    
    //  Get the list of objects in the org that have at least one updateable DateTime field.

    @AuraEnabled(cacheable=true)
    public static List<Selector> getOrgObjectList () {
        List<Selector> osList = new List<Selector>();
        for (Schema.SObjectType sot : Schema.getGlobalDescribe().values()) {
            Schema.DescribeSObjectResult dsor = sot.getDescribe();
            if (dsor.isUpdateable()) {
                Boolean foundOne = false;
                for (Schema.SObjectField field : dsor.fields.getMap().values()) {
                    Schema.DescribeFieldResult dfr = field.getDescribe();
                    if (dfr.isUpdateable() && dfr.getType().name() == 'DateTime') {
                        foundOne = true;
                        break;
                    }
                }
                if (foundOne) {
                    Selector s = new Selector();
                    s.apiName = dsor.getName();
                    s.label = dsor.getLabel();
                    osList.add(s);
                }
            }
        }
        return osList;
    }

    //  Get the list of DateTime fields in the given object

    @AuraEnabled(cacheable=true)
    public static List<Selector> getDateTimeFields (String objectApiName) {
        List<Selector> fieldList = new List<Selector>();
        if (objectApiName != '') {
            for (Schema.SObjectField field : Schema.getGlobalDescribe().get(objectAPIName).getDescribe().fields.getMap().values()) {
                Schema.DescribeFieldResult dfr = field.getDescribe();
                if (dfr.isUpdateable() && dfr.getType().name() == 'DateTime') {
                    Selector s = new Selector();
                    s.apiName = dfr.getName();
                    s.label = dfr.getLabel();
                    fieldList.add(s);
                }
            }
        }
        return fieldList;
    }

        
    //  Get the list of the date shift objects to put into the list on the Lightning component.
        
    @AuraEnabled(cacheable=true)
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
    
    @AuraEnabled(cacheable=false)
    public static DateDifference getMinutesToShift (String dateOfDemo, String objectApiName, String fieldApiName) {
        DateDifference diff = new DateDifference();
        diff.minutes = 0;
        diff.mostRecent = null;
        if (dateOfDemo != '' && objectApiName != '' && fieldApiName != '') {
            dateOfDemo = dateOfDemo.substring(0,4) + '-' + dateOfDemo.substring(5,7) + '-' + dateOfDemo.substring(8,10) + ' ' + dateOfDemo.substring(11,13) + ':' + dateOfDemo.substring(14,16) + ':' + dateOfDemo.substring(17,19);
            sObject record = Database.query('SELECT ' + fieldApiName + ' FROM ' + objectApiName + ' WHERE ' + fieldApiName + ' != null ORDER BY ' + fieldApiName + ' DESC LIMIT 1');
            if (record != null) {
                diff.mostRecent = (DateTime) record.get(fieldApiName);
                diff.minutes = (Integer) (Math.round((Decimal) (DateTime.valueOfGMT(dateOfDemo).getTime() - ((DateTime) record.get(fieldApiName)).getTime()) / 1000.0 / 60.0));
            }
        }
        return diff;
    }
    
    
    //  Shift the Date and DateTime fields of records based on the criteria specified.
    
    @AuraEnabled
    public static void dateShift (Integer minutesToShift, Integer daysToShift) {        
        for (ObjectItem item : getObjectItems ())
            Database.executeBatch(new DemoDateShifterBatch(minutesToShift, daysToShift, item.itemAPIName, getDateFieldNames(item.itemAPIName), item.itemWeekdaysOnly, item.itemAdjustMinutes));      
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
            item.itemCount = Database.countQuery('SELECT count() FROM ' + dso.Object_API_Name__c);
            item.itemRunningTotal = 0;
            item.itemRemaining = item.itemCount;
            item.itemPercentage = 0;
            item.itemToolTip = '';
            item.itemNumberOfErrors = 0;
            item.itemShiftFinished = false;
            return item;
        }
    }
    
    
    //  Utility to get all of the updateable Date and DateTime field API names from the given object.
    
    private static List<String> getDateFieldNames (String sObjectAPIName) {
        Set<String> dateFieldNames = new Set<String>();
        for (Schema.SObjectField field : Schema.getGlobalDescribe().get(sObjectAPIName).getDescribe().fields.getMap().values()) {
            Schema.DescribeFieldResult dfr = field.getDescribe();
            if (dfr.isUpdateable() && (dfr.getType().name() == 'Date' || dfr.getType().name() == 'DateTime'))
                dateFieldNames.add(dfr.getName());
        }
        dateFieldNames.removeAll(new List<String> {'SlaStartDate', 'SlaExitDate'});			//  Special case: never return these
        return new List<String>(dateFieldNames);
   }    
}
