#!/bin/bash
set -e
RESOURCE_GROUP='liam-game-host'
RESOURCE_GROUP_LOCATION='westeurope'
RESOURCE_PREFIX='liam-game-host'
SQL_USERNAME='liamSQL'
SQL_PASSWORD='aA1234567890'
VM_USERNAME='liam'
VM_PASSWORD='aA1234567890'

# Create resource group
az group create --name $RESOURCE_GROUP --location $RESOURCE_GROUP_LOCATION

# Create parameters object and run ARM deployment
params=$( echo '{"resourcePrefix": {"value": "'$RESOURCE_PREFIX'"},"username": {"value": "'$SQL_USERNAME'"},"password": {"value": "'$SQL_PASSWORD'"}}')
az group deployment create -g $RESOURCE_GROUP --template-file template.json --parameters "$params"
echo "Deployed Azure infrastructure"

#Grab the Storage Account URI and SQL DNS
storageAccount=$(az graph query -q  'resources | where type == "microsoft.storage/storageaccounts" | where resourceGroup == "'$RESOURCE_GROUP'" | project properties.primaryEndpoints.blob' -o tsv)
sqlDNS=$(az graph query -q  'resources | where type == "microsoft.sql/servers" | where resourceGroup == "'$RESOURCE_GROUP'" | project properties.fullyQualifiedDomainName' -o tsv)

#Get the SQL IP address
sqlIP=$(getent hosts $sqlDNS | cut -d' ' -f1)

#Copy the templates for the host break files to the current working directory
cp -rf templates/host/break .
sed -i "s|<IP>|$sqlIP|g" break/1 #replace IP address with SQL server IP
sed -i "s|<IP>|$sqlIP|g" break/3a #replace IP address with SQL server IP
sed -i "s|<URL>|$storageAccount|g" break/4a #replace storage account URI
sed -i "s|<URL>|$storageAccount|g" break/6a #replace storage account URI
sed -i "s|<URL>|$storageAccount|g" break/stress.ps1 #replace storage account URI

#Copy our files we've just modifed to our storage account
az storage copy --source-local-path break/*/ -d $storageAccount'game' --recursive
echo "Copied scripts to storage account"
#Copy our CustomScriptExtension PowerShell deployment for our application to the storage account
az storage copy -s templates/host/deploy.ps1 -d $storageAccount'game' --recursive
echo "Copied deploy.ps1 to storage account"

#Cipher our Storage Account URI
cipheredURL=$(echo $storageAccount'game' | tr '[A-Za-z]' '[N-ZA-Mn-za-m]')
mkdir -p client/break
i=0
#Loop through the files in our templates/client directory and add the ciphered URI
for filename in templates/client/break/*.sh; do
    i=$((i+1))
    sed "s|<URL>|$cipheredURL|g" "$filename" > client/break/$i.sh
done
echo "Created scripts to break application"

#Finally, copy the remaining artifacts required for the client deployment to ./client/
cp templates/client/template.json client/template.json
cp templates/client/deploy.sh client/deploy.sh
cp templates/client/_variables.sh client/_variables.sh
#Replace variables to represent the host deployment
sed -i "s|<VM_USERNAME>|$VM_USERNAME|g" client/_variables.sh
sed -i "s|<VM_PASSWORD>|$VM_PASSWORD|g" client/_variables.sh
sed -i "s|<SQL>|$sqlDNS|g" client/_variables.sh
sed -i "s|<SQL_USERNAME>|$SQL_USERNAME|g" client/_variables.sh
sed -i "s|<SQL_PASSWORD>|$SQL_PASSWORD|g" client/_variables.sh
sed -i "s|<STORAGE_URI>|$storageAccount|g" client/_variables.sh