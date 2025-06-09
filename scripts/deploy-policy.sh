#!/bin/bash

# Required parameters
RESOURCE_GROUP="rg-management"
LOCATION="eastus2"

# Display banner
echo "===================================================="
echo "Azure Policy Deployment Script - GEP-V"
echo "Date: 2025-06-09"
echo "===================================================="

# Create resource group if it doesn't exist
echo "Creating resource group $RESOURCE_GROUP..."
az group create --name $RESOURCE_GROUP --location $LOCATION --tags Environment=Production

# Deploy policy with BOTH tagName AND tagValue parameters
echo "Deploying tag policy with complete parameters..."
az deployment group create \
  --resource-group $RESOURCE_GROUP \
  --name policy-assignment \
  --parameters '{
    "assignmentName": {"value": "enforce-tag-policy"},
    "policyDefinitionId": {"value": "/providers/Microsoft.Authorization/policyDefinitions/1e30110a-5ceb-460c-a204-c1c3969c6d62"},
    "policyDescription": {"value": "Enforces Environment tag on all resources"},
    "displayName": {"value": "Require Environment Tag"},
    "enforcementMode": {"value": "Default"},
    "policyParameters": {"value": {
      "tagName": {"value": "Environment"},
      "tagValue": {"value": "Production"}
    }}
  }' \
  --template-file ./landing-zone/modules/policy.bicep

echo "Policy deployment completed"