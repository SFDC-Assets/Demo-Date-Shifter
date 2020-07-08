#!/bin/bash
readonly orgAlias="DateShifterScratch"

echo "*** Creating scratch org ..."
sfdx force:org:create -f config/project-scratch-def.json --setdefaultusername --setalias "$orgAlias" --durationdays 30
echo "*** Pushing metadata to scratch org ..."
sfdx force:source:push
echo "*** Assigning permission set to your user ..."
sfdx force:user:permset:assign --permsetname Demo_Shift_Dates
echo "*** Generating password for your user ..."
sfdx force:user:password:generate --targetusername $orgAlias
echo "*** Creating sample date shift objects ..."
sfdx force:apex:execute --apexcodefile scripts/apex/CreateDSOs.apex
echo "*** Creating sample records ..."
sfdx force:apex:execute --apexcodefile scripts/apex/CreateRecords.apex
#echo "*** Uploading sample date shift objects ..."
#sfdx force:data:tree:import --plan data/"Sample Date Shift Objects"/date-shift-object-Date_Shift_Object__c-plan.json
#echo "*** Uploading sample records ..."
#sfdx ETCopyData:import --configfolder data/"Sample Records"