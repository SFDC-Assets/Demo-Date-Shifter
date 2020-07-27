#!/bin/bash

readonly devHubOrgAlias="MyComponents"

sfdx force:data:soql:query \
    --targetusername "$devHubOrgAlias" \
    --query "SELECT ScratchOrg, Name, OrgName, Status, UserName, ExpirationDate FROM ScratchOrgInfo"