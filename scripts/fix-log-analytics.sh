#!/bin/bash
# ==============================================================
# DIRECT LOG ANALYTICS WORKSPACE CREATION - NO DEPENDENCIES
# Date: 2025-06-10 12:27:13
# Author: GEP-V
# ==============================================================

# Set variables
RESOURCE_GROUP="rg-management"
LOCATION="eastus2"
WORKSPACE_NAME="log-analytics-mgmt"

echo "Creating Log Analytics workspace directly..."
echo "Resource Group: $RESOURCE_GROUP"
echo "Location: $LOCATION"
echo "Workspace Name: $WORKSPACE_NAME"

# Use the direct resource create command
az resource create \
  --resource-group $RESOURCE_GROUP \
  --name $WORKSPACE_NAME \
  --resource-type "Microsoft.OperationalInsights/workspaces" \
  --location $LOCATION \
  --properties '{"sku":{"name":"PerGB2018"},"retentionInDays":30}' \
  --tags Environment=Production DeployedBy=GEP-V DeployedAt="2025-06-10 12:27:13"

echo "Log Analytics workspace creation completed."