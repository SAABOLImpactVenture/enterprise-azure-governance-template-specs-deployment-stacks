#!/bin/bash
# Direct Policy Assignment Script
# Created: 2025-06-09 23:43:43
# Author: GEP-V

# This script uses the simplest possible approach to assign an Azure policy
# with properly formatted parameters to avoid the "MissingPolicyParameter" error.

# Set variables
RESOURCE_GROUP="rg-management"
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
SCOPE="/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP"
POLICY_DEF_ID="1e30110a-5ceb-460c-a204-c1c3969c6d62"
TAG_NAME="Environment"
TAG_VALUE="Production"

echo "============================================================"
echo "POLICY ASSIGNMENT - DIRECT APPROACH"
echo "Created: 2025-06-09 23:43:43"
echo "Author: GEP-V"
echo "============================================================"

echo "Policy Definition ID: $POLICY_DEF_ID"
echo "Scope: $SCOPE"
echo "Tag Name: $TAG_NAME"
echo "Tag Value: $TAG_VALUE"
echo ""

# Delete any existing policy assignment
echo "Removing existing policy assignment (if any)..."
az policy assignment delete --name enforce-tag-policy --scope $SCOPE || true

# Create parameter string directly
PARAMS="{\"tagName\":{\"value\":\"$TAG_NAME\"},\"tagValue\":{\"value\":\"$TAG_VALUE\"}}"
echo "Using parameter string: $PARAMS"

# Create policy assignment directly (without template or parameter files)
echo "Creating policy assignment with direct parameters..."
az policy assignment create \
  --name "enforce-tag-policy" \
  --display-name "Require $TAG_NAME Tag" \
  --description "Enforces $TAG_NAME tag with value $TAG_VALUE on all resources" \
  --policy $POLICY_DEF_ID \
  --params "$PARAMS" \
  --scope $SCOPE \
  --enforcement-mode Default

# Verify the assignment was created successfully
echo ""
echo "Verifying policy assignment..."
az policy assignment show --name enforce-tag-policy --scope $SCOPE