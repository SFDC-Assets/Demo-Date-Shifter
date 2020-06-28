#!/bin/bash
sfdx force:data:tree:export \
    --query "SELECT Active__c, Adjust_Minutes__c, Object_API_Name__c, Weekdays_Only__c FROM Date_Shift_Object__c" \
    --prefix date-shift-object \
    --outputdir data/"Sample Date Shift Objects" \
    --plan