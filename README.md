![Creative Commons License](https://img.shields.io/badge/license-Creative%20Commons-success) ![In Development](https://img.shields.io/badge/status-In%20Development-yellow)

# Demo Date Shifter

This package contains tabs, Lightning components, and other support to shift `Date` and `DateTime` fields in selected objects. The user specifies which objects whose date fields are to be adjusted, a condition that tells how the dates are to be relatively shifted, and a date and time to shift to.

![Demo Shift Dates](/images/ShiftDates.gif)

## Summary

This component was inspired by the Salesforce SDO/CDO Perfect Date Wizard written by Salesforce's excellent Q-Branch staff and used by Salesforce Solutions Engineers, and includes some interesting enhancements:

- You can fine-tune the date and time shifting to the minute granularity, not just the day.
- You can shift dates backwards and forwards relative to any day, not just the current one.
- You can specify which field in which object you would like to shift the dates relative to.
- You can specify that certain dates, such as calendar events and task due dates, remain on weekdays after the date shifting.
- As a Lightning component, you can access it from a mobile device.

## Installation and Setup

Installation is easy: just read the disclaimer below and click on the **Deploy to Salesforce** button. This will install the component, all custom objects, tabs, and page layouts needed to use the component and assign all appropriate visibilities to the System Administrator profile. Simply create an app page using Lightning App Builder and drag the component onto the page where you would like it.

Next, as a System Administrator, open the `Date Shift Object` tab using the Lightning App Picker. Create a new **Date Shift Object** and enter the object's API name.

![Date Shift Object](/images/DateShiftObject.png)

The additional fields are as follows:

- **Active**: If selected (default), this object will be included in the list of objects in the component for date shifting. De-select to temporarily disable this object from date shifting.
- **Adjust Minutes**: Select to adjust minutes in `DateTime` fields relative to your date and time selection (useful for round-the-clock `DateTime` fields such as those you would find in objects like Cases); leave unselected (default) for objects to adjust the date portion only (useful for `DateTime` fields in objects like calendar events that typically start on hour or half-hour boundaries and should remain that way).
- **Weekdays Only**: If selected, then ensure that the adjusted date falls on a weekday. If the result of a field's shifting falls on a Saturday, it will be further adjusted to fall on the previous Friday; if the result of a field's shitfting falls on a Sunday, it will be further adjusted to fall on the following Monday. If unselected (default), no further adjustment will be made. This is useful for objects such as Event start and end dates or Task due dates which should always reflect working hours.

**IMPORTANT**: Out of the box, this package uses two custom case fields from the SDO/CDO: `DateTime_Opened_c__c` and `DateTime_Closed_c__c`. These fields are used by the Perfect Date Wizard to hold shifted dates since the standard fields `CreatedDate` and `ClosedDate` cannot be updated. Aside from these two custom fields, this package does not use anything from the Perfect Date Wizard and has not been tested to work with it. The Wizard uses custom fields beginning with `DB_` to track shifts in the dates, while this component uses the explicit date condition that you specify. The component there should have no problem working with dates that have been shifted by the Perfect Date Wizard, but the Wizard might have issues after your using this component. Bottom line: choose the Perfect Date Wizard or this component, but not both.

## For the Advanced User

The component ships with two out-of-the-box conditions for which to shift the dates: the most recent case open date and the most recent case closed date. If you would like to try your hand creating other conditions:

- Modify the component markup to add an `option` to the `lightning:select`. Delete any `option`s you don't want.
- Find the `conditionQueries` map in the `DemoShiftDates` Apex class and modify it to use whichever `DateTime` field of whatever object you wish. Make sure to include a SOQL query string that will return a single record and make sure that the string in your new entry matches the `value` in the `option` you added above.

## How to Deploy This Package to Your Org

I am a pre-sales Solutions Engineer for [Salesforce](https://www.salesforce.com) and I develop solutions for my customers to demonstrate the capabilities of the amazing Salesforce platform. *This package represents functionality that I have used for demonstration purposes  and the content herein is definitely not ready for actual production use; specifically, it has not been tested extensively nor has it been written with security and access controls in mind. By installing this package, you assume all risk for any consequences and agree not to hold me or my company liable.*  If you are OK with that ...

Simply click the button below and log into your org:

<a href="https://githubsfdeploy.herokuapp.com">
  <img alt="Deploy to Salesforce" src="https://raw.githubusercontent.com/afawcett/githubsfdeploy/master/src/main/webapp/resources/img/deploy.png">
</a>

Try this:

[![Deploy](https://deploy-to-sfdx.com/dist/assets/images/DeployToSFDX.svg)](https://deploy-to-sfdx.com)