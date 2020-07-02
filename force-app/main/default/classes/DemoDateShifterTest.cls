//  Test class and metbods for the DemoDateShifter Lightning component.
//
//  This code is provided AS IS, with no warranty or guarantee of suitability for use.
//  Contact: john.meyer@salesforce.com

@isTest
private without sharing class DemoDateShifterTest {

    private static final Integer DAYS = 7;
    private static final Integer MINUTES = DAYS * 24 * 60;
    private static Date today = Date.today();
    private static Date nextWeek = today.addDays(DAYS);
    private static DateTime now = DateTime.now();
    private static DateTime nextWeekTime = now.addMinutes(MINUTES);


    @testSetup
    static void setup () {

        List<Demo_Date_Shifter_Test_Current__c> current = new List<Demo_Date_Shifter_Test_Current__c>();
        for (Integer i = 0; i < 5; i++)
            current.add(new Demo_Date_Shifter_Test_Current__c (Sample_Date_Field__c = today, Sample_DateTime_Field__c = now));
        insert current;

        List<Demo_Date_Shifter_Test_Past__c> past = new List<Demo_Date_Shifter_Test_Past__c>();
        for (Integer i = 0; i < 5; i++)
            past.add(new Demo_Date_Shifter_Test_Past__c (Sample_Date_Field__c = today, Sample_DateTime_Field__c = now));
        insert past;        

        insert new Date_Shift_Object__c(
            Object_API_Name__c = 'Demo_Date_Shifter_Test_Current__c',
            Active__c = true,
            Adjust_Minutes__c = true,
            Weekdays_Only__c = false
        );
        insert new Date_Shift_Object__c(
            Object_API_Name__c = 'Demo_Date_Shifter_Test_Past__c',
            Active__c = true,
            Adjust_Minutes__c = false,
            Weekdays_Only__c = true
        );
    }

    @isTest
    static void testGetOrgObjectList () {

        DemoDateShifter.Selector current = new DemoDateShifter.Selector();

        Test.startTest();
        List<DemoDateShifter.Selector> selectors = DemoDateShifter.getOrgObjectList();
        Test.stopTest();

        Boolean found = false;
        for (DemoDateShifter.Selector selector : selectors)
            if (selector.apiName == 'Demo_Date_Shifter_Test_Current__c') {
                found = true;
                break;
            }
        System.assert(found);
    }

    @isTest
    static void testCustomDateShifterSettings () {

        Test.startTest();

        DemoDateShifter.DateShifterSettings setting = DemoDateShifter.getCustomDateShifterSettings();
        System.assert(!setting.settingsFound);

        DemoDateShifter.setCustomDateShifterSettings ('Demo_Date_Shifter_Test_Current__c', 'Sample_DateTime_Field__c');
        setting = DemoDateShifter.getCustomDateShifterSettings();
        System.assert(setting.settingsFound);

        DemoDateShifter.deleteCustomDateShifterSettings ();
        setting = DemoDateShifter.getCustomDateShifterSettings();
        System.assert(!setting.settingsFound);

        Test.stopTest();
    }

    @isTest
    static void testGetDateTimeFields () {

        Test.startTest();
        List<DemoDateShifter.Selector> selectors = DemoDateShifter.getDateTimeFields('Demo_Date_Shifter_Test_Current__c');
        Test.stopTest();

        Boolean found = false;
        for (DemoDateShifter.Selector selector : selectors)
            if (selector.apiName == 'Sample_DateTime_Field__c') {
                found = true;
                break;
            }
        System.assert(found);
    }

    @isTest
    static void testGetMinutesToShift () {
        Test.startTest();
        DemoDateShifter.DateDifference diff = DemoDateShifter.getMinutesToShift(now.format('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'','GMT'),
            'Demo_Date_Shifter_Test_Current__c', 'Sample_DateTime_Field__c');
        Test.stopTest();
        System.assert(diff.minutes < 2);
    }

    @isTest
    static void testDateShift () {

        Test.startTest();
        DemoDateShifter.dateShift(MINUTES, DAYS);
        Test.stopTest();

        Demo_Date_Shifter_Test_Current__c current = [SELECT Sample_Date_Field__c, Sample_DateTime_Field__c FROM Demo_Date_Shifter_Test_Current__c LIMIT 1];
        System.assert(current.Sample_Date_Field__c.isSameDay(nextWeek));
        System.assert(Math.abs(current.Sample_DateTime_Field__c.getTime() - nextWeekTime.getTime()) < 10000);
    }

}
