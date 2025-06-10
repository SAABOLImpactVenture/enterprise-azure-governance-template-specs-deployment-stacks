#!/bin/bash
# Simplified Direct Policy Assignment Script
# Created: 2025-06-10 12:17:59
# Author: GEP-V

# Set basic variables
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
RESOURCE_GROUP="rg-management"
SCOPE="/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP"

echo "==== POLICY ASSIGNMENT SCRIPT ===="
echo "Created: 2025-06-10 12:17:59"
echo "Author: GEP-V"
echo "Subscription: $SUBSCRIPTION_ID"
echo "Resource Group: $RESOURCE_GROUP"
echo "Scope: $SCOPE"
echo "============================"

# Delete any existing policy assignment
echo "Removing existing policy assignment (if any)..."
az policy assignment delete --name enforce-tag-policy --scope $SCOPE 2>/dev/null || true

# Create a parameters file with the simplest possible format
echo '{"tagName":{"value":"Environment"},"tagValue":{"value":"Production"}}' > policy-params.json
echo "Parameter file content:"
cat policy-params.json

# Assign the policy using the parameter file
echo "Assigning policy with parameter file..."
az policy assignment create \
  --name enforce-tag-policy \
  --display-name "Require Environment Tag" \
  --description "Enforces Environment tag on all resources" \
  --policy 1e30110a-5ceb-460c-a204-c1c3969c6d62 \
  --params @policy-params.json \
  --scope $SCOPE \
  --enforcement-mode Default

# Verify policy assignment
echo "Verifying policy assignment..."
az policy assignment show --name enforce-tag-policy --scope $SCOPE