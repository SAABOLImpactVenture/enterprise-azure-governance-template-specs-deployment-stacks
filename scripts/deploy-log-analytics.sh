#!/bin/bash
# ==============================================================================
# DIRECT LOG ANALYTICS WORKSPACE CREATION - NO EXTERNAL DEPENDENCIES
# Created: 2025-06-10 12:36:03
# Author: GEP-V
# ==============================================================================

# Set variables (update these as needed)
SUBSCRIPTION_ID="your-subscription-id"  # Replace with actual ID or set with: SUBSCRIPTION_ID=$(az account show --query id -o tsv)
RESOURCE_GROUP="rg-management"
LOCATION="eastus2"
WORKSPACE_NAME="log-analytics-mgmt"

# Set subscription context
echo "Setting subscription context to $SUBSCRIPTION_ID..."
az account set --subscription $SUBSCRIPTION_ID

# Create resource group if it doesn't exist
echo "Ensuring resource group $RESOURCE_GROUP exists..."
az group show --name $RESOURCE_GROUP > /dev/null 2>&1 || \
  az group create --name $RESOURCE_GROUP --location $LOCATION

# Check if workspace already exists
echo "Checking if Log Analytics workspace already exists..."
EXISTING_WORKSPACE=$(az resource list \
  --resource-group $RESOURCE_GROUP \
  --resource-type "Microsoft.OperationalInsights/workspaces" \
  --query "[?name=='$WORKSPACE_NAME'].id" -o tsv)

if [ -n "$EXISTING_WORKSPACE" ]; then
  echo "Workspace already exists with ID: $EXISTING_WORKSPACE"
  WORKSPACE_ID=$EXISTING_WORKSPACE
else
  # Create workspace using direct resource creation (no templates)
  echo "Creating Log Analytics workspace directly..."
  
  PROPERTIES=$(cat <<EOF
{
  "sku": {
    "name": "PerGB2018"
  },
  "retentionInDays": 30,
  "features": {
    "enableLogAccessUsingOnlyResourcePermissions": true
  },
  "publicNetworkAccessForIngestion": "Enabled",
  "publicNetworkAccessForQuery": "Enabled"
}
EOF
)

  TAGS="Environment=Production DeployedBy=GEP-V DeployedAt=\"2025-06-10 12:36:03\""
  
  echo "Creating workspace with properties:"
  echo "$PROPERTIES"
  
  WORKSPACE_RESULT=$(az resource create \
    --resource-group $RESOURCE_GROUP \
    --name $WORKSPACE_NAME \
    --resource-type "Microsoft.OperationalInsights/workspaces" \
    --location $LOCATION \
    --properties "$PROPERTIES" \
    --tags $TAGS)
  
  if [ $? -eq 0 ]; then
    WORKSPACE_ID=$(echo "$WORKSPACE_RESULT" | jq -r '.id')
    echo "Log Analytics workspace created with ID: $WORKSPACE_ID"
  else
    echo "ERROR: Failed to create Log Analytics workspace"
    echo "$WORKSPACE_RESULT"
    exit 1
  fi
fi

echo "Workspace ID: $WORKSPACE_ID"
echo "Deployment complete."