#!/bin/bash
# Enterprise Azure Landing Zone Deployment Script
# Created: 2025-06-09
# Author: GEP-V

# Set variables
RESOURCE_GROUP="rg-management"
LOCATION="eastus2"

# Create resource group if it doesn't exist
echo "Creating resource group $RESOURCE_GROUP..."
az group create --name $RESOURCE_GROUP --location $LOCATION --tags Environment=Production

# Deploy policy with parameters file
echo "Deploying policy assignment..."
az deployment group create \
  --resource-group $RESOURCE_GROUP \
  --name policy-assignment \
  --template-file ./landing-zone/modules/policy.bicep \
  --parameters @./landing-zone/parameters/policy-parameters.json

# Deploy Log Analytics workspace
echo "Deploying Log Analytics workspace..."
az deployment group create \
  --resource-group $RESOURCE_GROUP \
  --name log-analytics \
  --template-file ./landing-zone/modules/log-analytics.bicep \
  --parameters workspaceName=log-analytics-mgmt \
               location=$LOCATION \
               retentionInDays=30 \
               sku=PerGB2018

# List deployed resources
echo "Listing deployed resources..."
az resource list --resource-group $RESOURCE_GROUP -o table