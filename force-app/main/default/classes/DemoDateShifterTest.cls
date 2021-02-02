//  Test class and metbods for the DemoDateShifter Lightning component.
//
//  This code is provided AS IS, with no warranty or guarantee of suitability for use.
//  Contact: john.meyer@salesforce.com

@isTest
private without sharing class DemoDateShifterTest {

    private static final Integer DAYS = 7;
    private static final Integer MINUTES = DAYS * 24 * 60;
    private static final Date TODAY = Date.today();
    private static final DateTime NOW = DateTime.now();
    private static final Id ME = UserInfo.getUserId();


    @testSetup
    static void setup () {

        List<Event> events = new List<Event>();
        for (Integer i = 0; i < 7; i++)
            events.add(new Event (
                OwnerId = ME,
                StartDateTime = NOW.addDays(i),
                DurationInMinutes = 30
            ));
        insert events;

        List<Task> tasks = new List<Task>();
        for (Integer i = 0; i < 7; i++)
            tasks.add(new Task (
                OwnerId = ME,
                Status = 'Not Started',
                Subject = 'Test',
                Priority = 'Normal',
                ActivityDate = TODAY.addDays(i)
            ));
        insert tasks;        

        insert new Date_Shift_Object__c(
            Object_API_Name__c = 'Event',
            Active__c = true,
            Adjust_Minutes__c = true,
            Weekdays_Only__c = false
        );
        insert new Date_Shift_Object__c(
            Object_API_Name__c = 'Task',
            Active__c = true,
            Adjust_Minutes__c = false,
            Weekdays_Only__c = true
        );
    }

    @isTest
    static void testGetOrgObjectList () {

        System.Test.startTest();

        List<DemoDateShifter.Selector> selectors = DemoDateShifter.getOrgObjectList();
        Boolean found = false;
        for (DemoDateShifter.Selector selector : selectors)
            if (selector.apiName == 'Task') {
                found = true;
                break;
            }
        System.assert(found);

        System.Test.stopTest();
    }

    @isTest
    static void testCustomDateShifterSettings () {

        System.Test.startTest();

        DemoDateShifter.DateShifterSettings setting = DemoDateShifter.getCustomDateShifterSettings();
        System.assert(!setting.settingsFound);

        DemoDateShifter.setCustomDateShifterSettings ('Event', 'StartDateTime');
        setting = DemoDateShifter.getCustomDateShifterSettings();
        System.assert(setting.settingsFound);

        DemoDateShifter.deleteCustomDateShifterSettings ();
        setting = DemoDateShifter.getCustomDateShifterSettings();
        System.assert(!setting.settingsFound);

        System.Test.stopTest();
    }

    @isTest
    static void testGetDateTimeFields () {

        System.Test.startTest();

        List<DemoDateShifter.Selector> selectors = DemoDateShifter.getDateTimeFields('Event');
        Boolean found = false;
        for (DemoDateShifter.Selector selector : selectors)
            if (selector.apiName == 'StartDateTime') {
                found = true;
                break;
            }
        System.assert(found);

        System.Test.stopTest();
    }

    @isTest
    static void testGetMinutesToShift () {

        System.Test.startTest();

        DemoDateShifter.DateDifference diff;
        diff = DemoDateShifter.getMinutesToShift(NOW.format('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'','GMT'), 'Event', 'Subject');
        System.assert(!diff.validQuery);
        diff = DemoDateShifter.getMinutesToShift(NOW.format('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'','GMT'), 'Event', 'StartDateTime');
        System.assert(diff.validQuery);

        System.Test.stopTest();
    }

    @isTest
    static void testDateShift () {

        System.Test.startTest();
        DemoDateShifter.dateShift(MINUTES, DAYS);
        System.Test.stopTest();
    }

}
