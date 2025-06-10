#!/bin/bash
# ==============================================================================
# DIRECT LOG ANALYTICS WORKSPACE DEPLOYMENT - NO EXTERNAL TEMPLATES
# ==============================================================================
# Created: 2025-06-10 12:53:53 UTC
# Author: GEP-V

# Set script to exit on error
set -e

# Variables
RESOURCE_GROUP="rg-management"
LOCATION="eastus2"
WORKSPACE_NAME="log-analytics-mgmt"
TIMESTAMP="2025-06-10 12:53:53"
AUTHOR="GEP-V"

echo "===================================================="
echo "DIRECT LOG ANALYTICS WORKSPACE DEPLOYMENT"
echo "Created: $TIMESTAMP"
echo "Author: $AUTHOR"
echo "===================================================="

echo "Deploying Log Analytics workspace..."
echo "Resource Group: $RESOURCE_GROUP"
echo "Location: $LOCATION"
echo "Workspace Name: $WORKSPACE_NAME"

# Check if workspace already exists
EXISTING_WORKSPACE=$(az monitor log-analytics workspace list \
  --resource-group $RESOURCE_GROUP \
  --query "[?name=='$WORKSPACE_NAME'].id" -o tsv 2>/dev/null || echo "")

if [ -n "$EXISTING_WORKSPACE" ]; then
  echo "Workspace already exists with ID: $EXISTING_WORKSPACE"
  WORKSPACE_ID=$EXISTING_WORKSPACE
else
  # Create workspace using direct resource creation
  echo "Creating Log Analytics workspace using direct resource command..."
  
  WORKSPACE_RESULT=$(az resource create \
    --resource-group $RESOURCE_GROUP \
    --name $WORKSPACE_NAME \
    --resource-type "Microsoft.OperationalInsights/workspaces" \
    --location $LOCATION \
    --properties '{"sku":{"name":"PerGB2018"},"retentionInDays":30,"features":{"enableLogAccessUsingOnlyResourcePermissions":true},"publicNetworkAccessForIngestion":"Enabled","publicNetworkAccessForQuery":"Enabled"}' \
    --tags Environment=Production DeployedBy=$AUTHOR DeployedAt="$TIMESTAMP")
  
  if [ $? -eq 0 ]; then
    WORKSPACE_ID=$(echo "$WORKSPACE_RESULT" | jq -r '.id')
    echo "Log Analytics workspace created with ID: $WORKSPACE_ID"
  else
    echo "ERROR: Failed to create Log Analytics workspace"
    echo "$WORKSPACE_RESULT"
    exit 1
  fi
fi

echo "WORKSPACE_ID=$WORKSPACE_ID"
echo "===================================================="
echo "✅ Log Analytics workspace deployment completed successfully."
echo "===================================================="