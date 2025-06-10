#!/bin/bash
# ==============================================================
# DIRECT POLICY ASSIGNMENT - NO DEPENDENCIES
# Date: 2025-06-10 12:27:13
# Author: GEP-V
# ==============================================================

# Get the subscription ID
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
echo "Working with Subscription: $SUBSCRIPTION_ID"

# Set scope
RESOURCE_GROUP="rg-management"
SCOPE="/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP"
echo "Using scope: $SCOPE"

# Remove any existing policy assignment with this name
echo "Removing any existing policy assignment..."
az policy assignment delete --name enforce-tag-policy --scope $SCOPE 2>/dev/null || true

# Create parameter string directly - NO FILES OR VARIABLES
echo "Creating policy assignment with hard-coded parameters..."
az policy assignment create \
  --name "enforce-tag-policy" \
  --display-name "Require Environment Tag" \
  --description "Enforces Environment tag on all resources" \
  --policy "1e30110a-5ceb-460c-a204-c1c3969c6d62" \
  --params '{"tagName":{"value":"Environment"},"tagValue":{"value":"Production"}}' \
  --scope $SCOPE \
  --enforcement-mode Default

echo "Policy assignment completed."