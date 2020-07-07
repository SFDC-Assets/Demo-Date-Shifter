#!/bin/bash

sfdx force:package:version:create \
    --installationkeybypass \
    --wait 10 \
    --package "Demo Date Shifter" \
    --path "force-app" \
    --codecoverage \
    --targetdevhubusername "MyComponents"