#!/bin/bash

readonly tmpFile="data/tmp/output.csv"

sfdx force:data:soql:query --resultformat csv --query "SELECT Id FROM Demo_Date_Shifter_Test_Current__c" > "$tmpFile"
sfdx force:data:bulk:delete --sobjecttype Demo_Date_Shifter_Test_Current__c --csvfile "$tmpFile" --wait 10

sfdx force:data:soql:query --resultformat csv --query "SELECT Id FROM Demo_Date_Shifter_Test_Past__c" > "$tmpFile"
sfdx force:data:bulk:delete --sobjecttype Demo_Date_Shifter_Test_Past__c --csvfile "$tmpFile" --wait 10

sfdx force:data:soql:query --resultformat csv --query "SELECT Id FROM Demo_Date_Shifter_Test_Future__c" > "$tmpFile"
sfdx force:data:bulk:delete --sobjecttype Demo_Date_Shifter_Test_Future__c --csvfile "$tmpFile" --wait 10

rm -f "$tmpFile"