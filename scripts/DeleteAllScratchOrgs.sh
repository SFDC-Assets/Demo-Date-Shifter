#!/bin/bash

readonly devHubOrgAlias="MyComponents"
readonly tmpFile="ScratchOrgs.csv"

echo "*** Finding scratch orgs ..."
sfdx force:data:soql:query --query "SELECT Id FROM ScratchOrgInfo" --resultformat csv --targetusername "$devHubOrgAlias"  > "$tmpFile"
echo "*** Deleting found scratch orgs ..."
sfdx force:data:bulk:delete --csvfile "$tmpFile" --sobjecttype ScratchOrgInfo --wait 10 --targetusername "$devHubOrgAlias"
rm -f "$tmpFile"