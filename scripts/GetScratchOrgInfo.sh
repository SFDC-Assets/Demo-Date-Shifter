#!/bin/bash

readonly devHubOrgAlias="MyComponents"

sfdx force:data:soql:query \
    --targetusername "$devHubOrgAlias" \
    --query "SELECT ScratchOrg, Name, OrgName, ExpirationDate FROM ScratchOrgInfo WHERE Status = 'Active'"