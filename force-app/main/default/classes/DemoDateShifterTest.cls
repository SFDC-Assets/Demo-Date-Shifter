@isTest
private without sharing class DemoDateShifterTest {

    private static final Integer DAYS = 7;
    private static final Integer MINUTES = 7 * 24 * 60;
    private static Date today = Date.today();
    private static Date nextWeek = today.addDays(DAYS);
    private static DateTime now = DateTime.now();
    private static DateTime nextWeekTime = now.addMinutes(MINUTES);


    @TestSetup
    static void setup() {

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
    static void testGetOrgObjectList() {

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
    static void testDateShift() {

        Test.startTest();
        List<DemoDateShifter.Toast> toasts = DemoDateShifter.dateShift(MINUTES, DAYS);
        Test.stopTest();

        Demo_Date_Shifter_Test_Current__c current = [SELECT Sample_Date_Field__c, Sample_DateTime_Field__c FROM Demo_Date_Shifter_Test_Current__c LIMIT 1];
        System.assert(current.Sample_Date_Field__c.isSameDay(nextWeek));
        System.assert(Math.abs(current.Sample_DateTime_Field__c.getTime() - nextWeekTime.getTime()) < 2000);
    }

}
