#!/bin/bash

sfdx force:package:create \
    --packagetype "Unlocked" \
    --nonamespace \
    --name "Demo Date Shifter" \
    --description "This package contains code and metadata for the Salesforce Demo Date Shifter Lightning component" \
    --path "force-app" \
    --targetdevhubusername "MyComponents"