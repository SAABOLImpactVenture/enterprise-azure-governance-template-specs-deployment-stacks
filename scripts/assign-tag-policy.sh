#!/bin/bash
# Direct Azure Policy Assignment Script
# Created: 2025-06-09 23:22:53
# Author: GEP-V

# Set variables
RG_NAME="rg-management"
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
SCOPE="/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG_NAME"
POLICY_ID="1e30110a-5ceb-460c-a204-c1c3969c6d62"

# Remove existing policy assignment if it exists
echo "Removing any existing policy assignment..."
az policy assignment delete --name enforce-tag-policy --scope $SCOPE 2>/dev/null || true

# Create a parameters file
echo "Creating policy parameters file..."
cat > policy-parameters.json << EOF
{
  "tagName": {
    "value": "Environment"
  },
  "tagValue": {
    "value": "Production"
  }
}
EOF

echo "Parameters file content:"
cat policy-parameters.json

# Create the policy assignment using a parameters file
echo "Creating policy assignment with parameters file..."
az policy assignment create \
  --name "enforce-tag-policy" \
  --display-name "Require Environment Tag" \
  --description "Enforces Environment tag on all resources" \
  --policy $POLICY_ID \
  --params @policy-parameters.json \
  --scope $SCOPE \
  --enforcement-mode Default