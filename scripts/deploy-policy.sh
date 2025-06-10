#!/bin/bash
# ==============================================================================
# DIRECT POLICY ASSIGNMENT - NO EXTERNAL DEPENDENCIES
# Created: 2025-06-10 12:36:03
# Author: GEP-V
# ==============================================================================

# Set variables (update these as needed)
SUBSCRIPTION_ID="your-subscription-id"  # Replace with actual ID or set with: SUBSCRIPTION_ID=$(az account show --query id -o tsv)
RESOURCE_GROUP="rg-management"
SCOPE="/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP"
POLICY_DEF_ID="1e30110a-5ceb-460c-a204-c1c3969c6d62"
POLICY_NAME="enforce-tag-policy"

# Set subscription context
echo "Setting subscription context to $SUBSCRIPTION_ID..."
az account set --subscription $SUBSCRIPTION_ID

# Remove any existing policy assignment with this name
echo "Removing any existing policy assignment..."
az policy assignment delete --name $POLICY_NAME --scope $SCOPE 2>/dev/null || true

# Create a parameters JSON file
echo "Creating parameters file..."
cat > policy-params.json << EOF
{
  "tagName": {
    "value": "Environment"
  },
  "tagValue": {
    "value": "Production"
  }
}
EOF

echo "Parameter file content:"
cat policy-params.json

# Assign the policy using the parameter file
echo "Assigning policy with parameter file..."
POLICY_RESULT=$(az policy assignment create \
  --name $POLICY_NAME \
  --display-name "Require Environment Tag" \
  --description "Enforces Environment tag on all resources" \
  --policy $POLICY_DEF_ID \
  --params @policy-params.json \
  --scope $SCOPE \
  --enforcement-mode Default)

if [ $? -eq 0 ]; then
  echo "Policy assignment successful!"
  POLICY_ID=$(echo "$POLICY_RESULT" | jq -r '.id')
  echo "Policy ID: $POLICY_ID"
else
  echo "Policy assignment failed. Trying alternative approach..."
  
  # Try direct inline parameters approach
  POLICY_RESULT=$(az policy assignment create \
    --name $POLICY_NAME \
    --display-name "Require Environment Tag" \
    --description "Enforces Environment tag on all resources" \
    --policy $POLICY_DEF_ID \
    --params '{"tagName":{"value":"Environment"},"tagValue":{"value":"Production"}}' \
    --scope $SCOPE \
    --enforcement-mode Default)
  
  if [ $? -eq 0 ]; then
    echo "Policy assignment with inline parameters successful!"
    POLICY_ID=$(echo "$POLICY_RESULT" | jq -r '.id')
    echo "Policy ID: $POLICY_ID"
  else
    echo "All policy assignment attempts failed."
    echo "$POLICY_RESULT"
    exit 1
  fi
fi

echo "Verifying policy assignment..."
az policy assignment show --name $POLICY_NAME --scope $SCOPE

echo "Deployment complete."