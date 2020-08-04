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

        List<Shipment> shipments = new List<Shipment>();
        for (Integer i = 0; i < 7; i++)
            shipments.add(new Shipment (
                ShipToName = 'Test Name',
                ActualDeliveryDate = now.addDays(i)
            ));
        insert shipments;

        List<Task> tasks = new List<Task>();
        for (Integer i = 0; i < 7; i++)
            tasks.add(new Task (
                OwnerId = UserInfo.getUserId(),
                Status = 'Not Started',
                Subject = 'Test',
                Priority = 'Normal',
                ActivityDate = today.addDays(i)
            ));
        insert tasks;        

        insert new Date_Shift_Object__c(
            Object_API_Name__c = 'Shipment',
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

        Test.startTest();

        List<DemoDateShifter.Selector> selectors = DemoDateShifter.getOrgObjectList();
        Boolean found = false;
        for (DemoDateShifter.Selector selector : selectors)
            if (selector.apiName == 'Task') {
                found = true;
                break;
            }
        System.assert(found);

        Test.stopTest();
    }

    @isTest
    static void testCustomDateShifterSettings () {

        Test.startTest();

        DemoDateShifter.DateShifterSettings setting = DemoDateShifter.getCustomDateShifterSettings();
        System.assert(!setting.settingsFound);

        DemoDateShifter.setCustomDateShifterSettings ('Shipment', 'ActualDeliveryDate');
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

        List<DemoDateShifter.Selector> selectors = DemoDateShifter.getDateTimeFields('Shipment');
        Boolean found = false;
        for (DemoDateShifter.Selector selector : selectors)
            if (selector.apiName == 'ActualDeliveryDate') {
                found = true;
                break;
            }
        System.assert(found);

        Test.stopTest();
    }

    @isTest
    static void testGetMinutesToShift () {

        Test.startTest();

        DemoDateShifter.DateDifference diff;
        diff = DemoDateShifter.getMinutesToShift(now.format('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'','GMT'),
            'Shipment', 'ExpectedDeliveryDate');
        System.assert(!diff.validQuery);
        diff = DemoDateShifter.getMinutesToShift(now.format('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'','GMT'),
            'Shipment', 'ActualDeliveryDate');
        System.assert(diff.validQuery);

        Test.stopTest();
    }

    @isTest
    static void testDateShift () {

        Test.startTest();

        DemoDateShifter.dateShift(MINUTES, DAYS);
        // Task tsk = [SELECT ActivityDate FROM Task ORDER BY ActivityDate ASC LIMIT 1];
        // Shipment ship = [SELECT ActualDeliveryDate FROM Shipment ORDER BY ActualDeliveryDate ASC LIMIT 1];

        //System.assert(tsk.ActivityDate.isSameDay(nextWeek));
        //System.assert(Math.abs(ship.ActualDeliveryDate.getTime() - nextWeekTime.getTime()) < 10000);

        Test.stopTest();
    }

}
