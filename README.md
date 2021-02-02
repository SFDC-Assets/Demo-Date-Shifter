![Creative Commons License](https://img.shields.io/badge/license-Creative%20Commons-success) ![Released](https://img.shields.io/badge/status-Released-success) ![Code Coverage](https://img.shields.io/badge/code%20coverage-89%25-success)


<h1 align="center">DEMO DATE SHIFTER</h1>
<p align="center">
This package contains tabs, Lightning components, and other support to shift `Date` and `DateTime` fields in selected objects. The user specifies which objects whose date fields are to be adjusted, a reference field in an object that tells how the dates are to be relatively shifted, and a date and time to shift to.
</p>

## Summary

As Salesforce SEs, we work hard to get demos just right, aligning dates and times on cases, tasks, events, and other records so that we can show things like case history, current tasks, and future events in order to tell a great story. Then weeks or months pass, we need to show the demo again, and all of those records are wildly out of date. We need a tool that shifts all of those dates by the same amount relative to the new demo date so that some criterion is satisfied, such as "all case closed dates cannot be later than the date and time of the new demo".

This component was inspired by the Salesforce SDO/CDO Perfect Date Wizard written by Salesforce's amazing Q-Branch staff and used by Salesforce Solutions Engineers, and includes some interesting enhancements:

- You can fine-tune the date and time shifting to the minute granularity, not just the day.
- You can shift dates backwards and forwards relative to any day, not just the current one.
- You can specify which field in which object you would like to shift the dates relative to.
- You can specify that certain dates, such as calendar events and task due dates, remain on weekdays after the date shifting.
- You can watch the progress of the date shift as it completes.

**IMPORTANT**: This tool does not rely on anything from the Perfect Date Wizard and is not intended to work with it. The Perfect Date Wizard uses custom fields beginning with `DB_` to track shifts in the dates, while this component uses the explicit date condition that you specify. The component will have no problem working with dates that have been shifted by the Perfect Date Wizard, but the Perfect Date Wizard might have issues after you use this tool, since the Demo Date Shifter does not update any of the `DB_` fields. Bottom line: choose the Perfect Date Wizard or this component, but not both.

## Installation and Setup

1. To install the component, just read the disclaimer below and click on the **Install the Package** link. This will install the component and all custom objects, tabs, and page layouts needed to use the component.

1. Make sure you assign the permission set `Demo Shift Dates` to the System Administrator or any other person who is to use the component.

1. Next, create an app page using Lightning App Builder and drag the component onto the page where you would like it. The component looks best on a page with the standard "Two Regions" layout.

1. Finally, as a System Administrator, open the `Date Shift Object` tab using the button on the component's "You have a little work to do" screen. Create new **Date Shift Object**s as you like.

![Date Shift Object](/images/DateShiftObject.png)

The additional fields on the Date Shift Object are as follows:

- **Active**: If selected (default), this object will be included in the list of objects in the component for date shifting. De-select to temporarily disable this object from date shifting.
- **Adjust Minutes**: Select to adjust minutes in `DateTime` fields relative to your date and time selection (useful for round-the-clock `DateTime` fields such as those you would find in objects like Cases); deselect for objects to adjust the date portion only (useful for `DateTime` fields in objects like calendar events that typically start on hour or half-hour boundaries and should remain that way).
- **Weekdays Only**: If selected, then ensure that the adjusted date falls on a weekday. If the result of a field's shifting falls on a Saturday, it will be further adjusted to fall on the previous Friday; if the result of a field's shitfting falls on a Sunday, it will be further adjusted to fall on the following Monday. If unselected (default), no further adjustment will be made. This is useful for objects such as Event start and end dates or Task due dates which should always reflect working hours.

## Shifting the Dates

You have two options for specifying the amount of time to shift.

- **By Basing it off a Most Recent Record in the Org**: In this scenario, we begin by asking the Demo Date Shifter to find a particular record in the org with a field that contains a date and time that should not be later than the date and time of the demo. An example would be a case closed date (`DateTime_Closed_c__c` if you are using an SDO or CDO) since cases cannot be closed in the future. The Demo Date Shifter then calculates the amount of time between the contents of that field in that record and the date and time of the demo that you specify in the date and time picker in the component. Once the object, field, and demo date and time are selected, you will see a confirmation in the lower part of the component showing you the most recent record for that object the Demo Date Shifter found and the amount of time that the dates will be shifted in the org. If you would like to bypass the object and field selection in the future, you can save the object and field selections in the org and the Demo Date Shifter will find them again the next time you log in.

![Based on Record](/images/ShiftBasedOnRecord.png)

- **By Explicitly Specifying the Amount of Time to Shift**: If you simply want the Demo Date Shifter to "brute force" shift all the dates and times in the objects you specify, you can use this option. Dates can be shifted forward or backward as you wish.

![Based on Time](/images/ShiftBasedOnTime.png)

## How to Deploy This Package to Your Org

I am a pre-sales Solutions Engineer for [Salesforce](https://www.salesforce.com) and I develop solutions for my customers to demonstrate the capabilities of the amazing Salesforce platform. *This package represents functionality that I have used for demonstration purposes and the content herein is definitely not ready for actual production use; specifically, it has not been tested extensively nor has it been written with security and access controls in mind. By installing this package, you assume all risk for any consequences and agree not to hold me or my company liable.*  If you are OK with that ...

[Install the Package](https://login.salesforce.com/packaging/installPackage.apexp?p0=04t2E000003ocQxQAI)

## Maintainer

[John Meyer / johnsfdemo](https://github.com/johnsfdemo)

**Current Version**: 1.6.1
