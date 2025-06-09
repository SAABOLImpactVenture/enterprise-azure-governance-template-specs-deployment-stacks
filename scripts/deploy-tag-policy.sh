#!/bin/bash
# Direct policy assignment script
# Created: 2025-06-09 22:56:50
# Author: GEP-V

# Set variables
RESOURCE_GROUP="rg-management"
LOCATION="eastus2"
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
SCOPE="/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP"

# Create resource group if it doesn't exist
echo "Creating resource group $RESOURCE_GROUP..."
az group create --name $RESOURCE_GROUP --location $LOCATION --tags Environment=Production

# Delete existing policy assignment if it exists
echo "Removing any existing policy assignment..."
az policy assignment delete --name enforce-tag-policy --scope $SCOPE 2>/dev/null || true

# Create policy assignment directly with Azure CLI
echo "Creating policy assignment using direct Azure CLI command..."
az policy assignment create \
  --name "enforce-tag-policy" \
  --display-name "Require Environment Tag" \
  --description "Enforces Environment tag on all resources" \
  --policy "1e30110a-5ceb-460c-a204-c1c3969c6d62" \
  --params '{"tagName":{"value":"Environment"},"tagValue":{"value":"Production"}}' \
  --scope $SCOPE \
  --enforcement-mode Default

echo "Policy assignment created successfully."