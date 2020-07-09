#!/bin/bash
readonly orgAlias="DateShifterScratch"

echo "*** Creating scratch org ..."
sfdx force:org:create -f config/project-scratch-def.json --targetdevhubusername MyComponents --setdefaultusername --setalias "$orgAlias" --durationdays 30 || exit 1
echo "*** Pushing metadata to scratch org ..."
sfdx force:source:push || exit 1
echo "*** Assigning permission set to your user ..."
sfdx force:user:permset:assign --permsetname Demo_Shift_Dates
echo "*** Generating password for your user ..."
sfdx force:user:password:generate --targetusername $orgAlias
echo "*** Creating sample date shift objects ..."
sfdx force:apex:execute --apexcodefile scripts/apex/CreateDSOs.apex
echo "*** Creating sample records ..."
sfdx force:apex:execute --apexcodefile scripts/apex/CreateRecords.apex