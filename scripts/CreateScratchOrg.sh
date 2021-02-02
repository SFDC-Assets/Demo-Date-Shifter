#!/bin/bash
readonly orgAlias="DateShifterScratch"
readonly devHubUserName="MyComponents"

echo "*** Creating scratch org ..."
sfdx force:org:create \
    --definitionfile config/project-scratch-def.json \
    --type scratch \
    --nonamespace \
    --targetdevhubusername "$devHubUserName" \
    --setdefaultusername \
    --setalias "$orgAlias" \
    --durationdays 30 \
    --loglevel error || exit 1
echo "*** Pushing metadata to scratch org ..."
sfdx force:source:push || exit 1
echo "*** Setting time zone for your user ..."
sfdx force:data:record:update --targetusername "$orgAlias" --sobjecttype User --where "Name='User User'" --values "TimeZoneSidKey='America/New_York'" --loglevel error
echo "*** Generating password for your user ..."
sfdx force:user:password:generate --targetusername $orgAlias --loglevel error
echo "*** Assigning permission set to your user ..."
sfdx force:user:permset:assign --permsetname Demo_Shift_Dates --loglevel error
echo "*** Creating sample date shift objects ..."
sfdx force:apex:execute --apexcodefile scripts/apex/CreateDSOs.apex --loglevel error
echo "*** Creating sample records ..."
sfdx force:apex:execute --apexcodefile scripts/apex/CreateRecords.apex --loglevel error
echo "*** Setting default date shift settings for user ..."
sfdx force:apex:execute --apexcodefile scripts/apex/SetDateShiftSettings.apex --loglevel error