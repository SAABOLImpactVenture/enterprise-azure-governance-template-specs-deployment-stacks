#!/bin/bash
# ==============================================================================
# DIAGNOSTICS SETTINGS CONFIGURATION - NO EXTERNAL DEPENDENCIES
# Created: 2025-06-10 12:36:03
# Author: GEP-V
# ==============================================================================

# Set variables (update these as needed)
SUBSCRIPTION_ID="your-subscription-id"  # Replace with actual ID or set with: SUBSCRIPTION_ID=$(az account show --query id -o tsv)
RESOURCE_GROUP="rg-management"
VNET_NAME="vnet-management"
WORKSPACE_NAME="log-analytics-mgmt"

# Set subscription context
echo "Setting subscription context to $SUBSCRIPTION_ID..."
az account set --subscription $SUBSCRIPTION_ID

# Check Microsoft.Insights registration status
echo "Checking Microsoft.Insights provider registration..."
INSIGHTS_STATUS=$(az provider show --namespace Microsoft.Insights --query "registrationState" -o tsv)
echo "Microsoft.Insights status: $INSIGHTS_STATUS"

if [ "$INSIGHTS_STATUS" != "Registered" ]; then
  echo "Microsoft.Insights is not registered. Registering now..."
  az provider register --namespace Microsoft.Insights
  
  echo "Waiting for registration to complete (this may take several minutes)..."
  while [ "$INSIGHTS_STATUS" != "Registered" ]; do
    echo "Checking registration status..."
    sleep 30
    INSIGHTS_STATUS=$(az provider show --namespace Microsoft.Insights --query "registrationState" -o tsv)
    echo "Microsoft.Insights status: $INSIGHTS_STATUS"
  done
  
  echo "Microsoft.Insights provider registration complete."
fi

# Get VNet and Log Analytics workspace IDs
echo "Getting VNet and Log Analytics workspace IDs..."
VNET_ID=$(az network vnet show --resource-group $RESOURCE_GROUP --name $VNET_NAME --query id -o tsv)
WORKSPACE_ID=$(az resource list --resource-group $RESOURCE_GROUP --resource-type "Microsoft.OperationalInsights/workspaces" --query "[?name=='$WORKSPACE_NAME'].id" -o tsv)

if [ -z "$VNET_ID" ] || [ -z "$WORKSPACE_ID" ]; then
  echo "ERROR: Could not find VNet or Log Analytics workspace."
  echo "VNet ID: $VNET_ID"
  echo "Workspace ID: $WORKSPACE_ID"
  exit 1
fi

echo "VNet ID: $VNET_ID"
echo "Workspace ID: $WORKSPACE_ID"

# Check if diagnostics are already configured
EXISTING_DIAG=$(az monitor diagnostic-settings list --resource "$VNET_ID" --query "[?name=='diag-to-log-analytics'].id" -o tsv 2>/dev/null || echo "")

if [ -n "$EXISTING_DIAG" ]; then
  echo "Diagnostics settings already exist for VNet"
else
  # Configure diagnostics settings
  echo "Creating diagnostic settings..."
  DIAG_RESULT=$(az monitor diagnostic-settings create \
    --name "diag-to-log-analytics" \
    --resource "$VNET_ID" \
    --workspace "$WORKSPACE_ID" \
    --logs '[{"category":"VMProtectionAlerts","enabled":true}]' \
    --metrics '[{"category":"AllMetrics","enabled":true}]')
  
  if [ $? -eq 0 ]; then
    echo "Diagnostics settings configured successfully."
  else
    echo "Failed to configure diagnostics settings."
    echo "$DIAG_RESULT"
    exit 1
  fi
fi

echo "Deployment complete."