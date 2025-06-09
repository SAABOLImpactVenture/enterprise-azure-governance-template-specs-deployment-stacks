#!/bin/bash
# Direct Log Analytics Workspace deployment
# Created: 2025-06-09 23:16:32
# Author: GEP-V

# Set variables
RESOURCE_GROUP="rg-management"
LOCATION="eastus2"
WORKSPACE_NAME="log-analytics-mgmt"
SKU="PerGB2018"
RETENTION_DAYS=30

# Create Log Analytics Workspace directly with Azure CLI
echo "Creating Log Analytics workspace directly with Azure CLI..."
az monitor log-analytics workspace create \
  --resource-group $RESOURCE_GROUP \
  --workspace-name $WORKSPACE_NAME \
  --location $LOCATION \
  --sku $SKU \
  --retention-time $RETENTION_DAYS \
  --tags Environment=Production DeployedBy=GEP-V DeployedAt="2025-06-09 23:16:32"

# Get workspace ID for later use
WORKSPACE_ID=$(az monitor log-analytics workspace show \
  --resource-group $RESOURCE_GROUP \
  --workspace-name $WORKSPACE_NAME \
  --query id -o tsv)

echo "Log Analytics workspace created with ID: $WORKSPACE_ID"