#!/bin/bash
# ==============================================================================
# DIRECT POLICY ASSIGNMENT FIX FOR MISSING tagValue PARAMETER
# Created: 2025-06-10 12:41:26
# Author: GEP-V
# ==============================================================================

# Set variables
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
RESOURCE_GROUP="rg-management"
SCOPE="/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP"
POLICY_DEF_ID="1e30110a-5ceb-460c-a204-c1c3969c6d62"
POLICY_NAME="enforce-tag-policy"

echo "=== POLICY ASSIGNMENT FIX ==="
echo "Created: 2025-06-10 12:41:26"
echo "Author: GEP-V"
echo "Subscription: $SUBSCRIPTION_ID"
echo "Resource Group: $RESOURCE_GROUP"
echo "=========================="

# Remove any existing policy assignment
echo "Removing existing policy assignment..."
az policy assignment delete --name $POLICY_NAME --scope $SCOPE 2>/dev/null || true

# Create policy assignment with BOTH required parameters
echo "Creating policy assignment with correct parameters..."
az policy assignment create \
  --name $POLICY_NAME \
  --display-name "Require Environment Tag" \
  --description "Enforces Environment tag on all resources" \
  --policy $POLICY_DEF_ID \
  --params '{"tagName":{"value":"Environment"},"tagValue":{"value":"Production"}}' \
  --scope $SCOPE \
  --enforcement-mode Default

# Verify policy assignment
echo "Verifying policy assignment..."
az policy assignment show --name $POLICY_NAME --scope $SCOPE --query "parameters"

echo "Fix completed."