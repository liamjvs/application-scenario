#!/bin/bash
set -e

source _variables.sh

az group create --name "$RESOURCE_GROUP" --location "$RESOURCE_GROUP_LOCATION"

params=$( echo '{"resourcePrefix": {"value": "'$RESOURCE_PREFIX'"},"username": {"value": "'$VM_USERNAME'"},"password": {"value": "'$VM_PASSWORD'"}, "sqlSettings": {"value": {"server": "'$SQL_SERVER'", "user": "'$SQL_USERNAME'", "password": "'$SQL_PASSWORD'"}}, "storageAccountURI": {"value": "'$STORAGE_URI'"}}')
az group deployment create -g $RESOURCE_GROUP --template-file template.json --parameters "$params"