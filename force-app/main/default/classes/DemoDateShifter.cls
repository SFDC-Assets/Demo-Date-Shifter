//  Controller for the DemoDateShifter Lightning component.
//
//  This code is provided AS IS, with no warranty or guarantee of suitability for use.
//  Contact: john.meyer@salesforce.com

public without sharing class DemoDateShifter {
    
    public class ObjectItem {
        @AuraEnabled public Id itemId;
        @AuraEnabled public String itemAPIName;
        @AuraEnabled public String itemLabel;
        @AuraEnabled public String itemLabelPlural;
        @AuraEnabled public Boolean itemWeekdaysOnly;
        @AuraEnabled public Boolean itemAdjustMinutes;
        @AuraEnabled public Integer itemCount;
    }

    public class Selector {
        @AuraEnabled public String label;
        @AuraEnabled public String apiName;
    }

    public class DateDifference {
        @AuraEnabled public Boolean validQuery;
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

        Date_Shifter_Saved_Settings__c savedSettings = Date_Shifter_Saved_Settings__c.getInstance();
        DateShifterSettings dsSettings = new DateShifterSettings();

        if (savedSettings.Object_API_Name__c == null) {
            dsSettings.settingsFound = false;
            dsSettings.objectApiNameIsValid = false;
            dsSettings.fieldApiNameIsValid = false;
        } else {
            dsSettings.objectApiName = savedSettings.Object_API_Name__c;
            dsSettings.fieldApiName = savedSettings.Field_API_Name__c;
            dsSettings.settingsFound = true;
            dsSettings.objectApiNameIsValid = true;
            dsSettings.fieldApiNameIsValid = Schema.getGlobalDescribe().get(savedSettings.Object_API_Name__c).getDescribe().fields.getMap().get(savedSettings.Field_API_Name__c) != null;
        }

        return dsSettings;
    }


    //  Set the user's custom setting.
    
    @AuraEnabled
    public static void setCustomDateShifterSettings (String objectApiName, String fieldApiName) {
        insert new Date_Shifter_Saved_Settings__c (
            Name = UserInfo.getUserName(),
            SetupOwnerId = UserInfo.getUserId(),
            Object_API_Name__c = objectApiName,       
            Field_API_Name__c = fieldApiName
        );
    }


    //  Remove user's custom setting.

    @AuraEnabled
    public static void deleteCustomDateShifterSettings () {
        List<Date_Shifter_Saved_Settings__c> settings = [SELECT Id FROM Date_Shifter_Saved_Settings__c WHERE SetupOwnerId = :UserInfo.getUserId() LIMIT 1];
        if (!settings.isEmpty())
            delete settings;
    }
    
    
    //  Get the list of objects in the org.

    @AuraEnabled(cacheable=true)
    public static List<Selector> getOrgObjectList () {

        List<Selector> objectList = new List<Selector>();

        for (Schema.SObjectType sot : Schema.getGlobalDescribe().values()) {
            Schema.DescribeSObjectResult dsor = sot.getDescribe();
            if (dsor.isUpdateable()) {
                Selector sel = new Selector();
                sel.apiName = dsor.getName();
                sel.label = dsor.getLabel();
                objectList.add(sel);
            }
        }

        return objectList;
    }


    //  Get the list of DateTime fields in the given object

    @AuraEnabled(cacheable=true)
    public static List<Selector> getDateTimeFields (String objectApiName) {

        List<Selector> fieldList = new List<Selector>();

        if (objectApiName != '') {
            for (Schema.SObjectField field : Schema.getGlobalDescribe().get(objectAPIName).getDescribe().fields.getMap().values()) {
                Schema.DescribeFieldResult dfr = field.getDescribe();
                if (dfr.isUpdateable() && dfr.getType().name() == 'DateTime') {
                    Selector sel = new Selector();
                    sel.apiName = dfr.getName();
                    sel.label = dfr.getLabel();
                    fieldList.add(sel);
                }
            }
        }

        return fieldList;
    }

        
    //  Get the list of the date shift objects.
        
    @AuraEnabled(cacheable=true)
    public static List<ObjectItem> getDateShiftObjects () {

        List<ObjectItem> objectItems = new List<ObjectItem>();        
        for (Date_Shift_Object__c dso : [SELECT Object_API_Name__c FROM Date_Shift_Object__c WHERE Active__c = true ORDER BY Object_API_Name__c ASC])
            objectItems.add(getObjectItem(dso.Object_API_Name__c));       

        return objectItems;
    }
    
    
    //  Calculate the number of minutes to shift.
    
    @AuraEnabled(cacheable=false)
    public static DateDifference getMinutesToShift (String dateOfDemo, String objectApiName, String fieldApiName) {

        DateDifference diff = new DateDifference();
        diff.minutes = 0;
        diff.mostRecent = null;

        if (dateOfDemo != '' && objectApiName != '' && fieldApiName != '') {
            List<sObject> records = Database.query('SELECT ' + fieldApiName + ' FROM ' + objectApiName + ' WHERE ' + fieldApiName + ' != null ORDER BY ' + fieldApiName + ' DESC LIMIT 1');
            if (records.isEmpty()) {
                diff.validQuery = false;
            } else {
                diff.validQuery = true;
                sObject record = records[0];
                dateOfDemo = dateOfDemo.substring(0,4) + '-' + dateOfDemo.substring(5,7) + '-' + dateOfDemo.substring(8,10) + ' ' + dateOfDemo.substring(11,13) + ':' + dateOfDemo.substring(14,16) + ':' + dateOfDemo.substring(17,19);
                diff.mostRecent = (DateTime) record.get(fieldApiName);
                diff.minutes = (Integer) (Math.round((Decimal) (DateTime.valueOfGMT(dateOfDemo).getTime() - ((DateTime) record.get(fieldApiName)).getTime()) / 1000.0 / 60.0));
            }
        }

        return diff;
    }
    
    
    //  Shift the Date and DateTime fields of records based on the criteria specified.
    
    @AuraEnabled
    public static void dateShift (Integer minutesToShift, Integer daysToShift) {        
        for (ObjectItem item : getDateShiftObjects())
            Database.executeBatch(new DemoDateShifterBatch(minutesToShift, daysToShift, item.itemAPIName, getDateFieldNames(item.itemAPIName), item.itemWeekdaysOnly, item.itemAdjustMinutes));      
    }
    
    
    //  Utility to return an ObjectItem given an sObject API name.  Not the most efficient way of doing things, but we put a limit on
    //  the number of objects in the org that can have their dates shifted in the user interface.
    
    private static ObjectItem getObjectItem (String sObjectAPIName) {
        
        Date_Shift_Object__c dso = [SELECT Object_API_Name__c, Weekdays_Only__c, Adjust_Minutes__c FROM Date_Shift_Object__c WHERE Active__c = true AND Object_API_Name__c = :sObjectAPIName LIMIT 1];        
        Schema.DescribeSObjectResult dsor = Schema.getGlobalDescribe().get(dso.Object_API_Name__c).getDescribe();
        ObjectItem item = new ObjectItem();
 
        item.itemId = dso.Id;
        item.itemAPIName = dso.Object_API_Name__c;
        item.itemLabel = dsor.getLabel();
        item.itemLabelPlural = dsor.getLabelPlural();
        item.itemWeekdaysOnly = dso.Weekdays_Only__c;
        item.itemAdjustMinutes = dso.Adjust_Minutes__c;
        item.itemCount = Database.countQuery('SELECT count() FROM ' + dso.Object_API_Name__c);

        return item;
    }
    
    
    //  Utility to get all of the updateable Date and DateTime field API names from the given object.
    
    private static List<String> getDateFieldNames (String sObjectAPIName) {

        Set<String> dateFieldNames = new Set<String>();

        for (Schema.SObjectField field : Schema.getGlobalDescribe().get(sObjectAPIName).getDescribe().fields.getMap().values()) {
            Schema.DescribeFieldResult dfr = field.getDescribe();
            String typeName = dfr.getType().name();
            if (dfr.isUpdateable() && (typeName == 'Date' || typeName == 'DateTime'))
                dateFieldNames.add(dfr.getName());
        }
        dateFieldNames.removeAll(new List<String> {'SlaStartDate', 'SlaExitDate'});			//  Special case: never return these

        return new List<String>(dateFieldNames);
   }    
}
