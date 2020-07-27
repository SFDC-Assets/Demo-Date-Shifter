#!/bin/bash

readonly devHubOrgAlias="MyComponents"
readonly tmpFile="ScratchOrgs.csv"
readonly scratchOrgId=$(sfdx force:org:display --json | jq .result.id | sed s/\"//g | cut -c 1-15)

sfdx force:data:soql:query \
    --query "SELECT Id FROM ScratchOrgInfo WHERE ScratchOrg = '$scratchOrgId'" \
    --resultformat csv \
    --targetusername "$devHubOrgAlias" > "$tmpFile"
echo "*** Deleting found scratch org $scratchOrgId ..."
sfdx force:data:bulk:delete --csvfile "$tmpFile" --sobjecttype ScratchOrgInfo --wait 10 --targetusername "$devHubOrgAlias" --loglevel error
rm -f "$tmpFile"