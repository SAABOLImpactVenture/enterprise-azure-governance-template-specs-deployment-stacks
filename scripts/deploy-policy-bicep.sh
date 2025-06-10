#!/bin/bash
# ==============================================================================
# AZURE POLICY DEPLOYMENT SCRIPT USING BICEP
# ==============================================================================
# Created: 2025-06-10 12:50:16 UTC
# Author: GEP-V
#
# This script deploys an Azure policy assignment using a Bicep template with
# properly formatted parameters including the required tagValue parameter.

# Set script to exit on error
set -e

# ==========================================================================
# VARIABLES
# ==========================================================================
RESOURCE_GROUP="rg-management"
LOCATION="eastus2"
DEPLOYMENT_NAME="policy-deployment-$(date +%s)"
BICEP_FILE="./landing-zone/modules/policy.bicep"
POLICY_DEF_ID="/providers/Microsoft.Authorization/policyDefinitions/1e30110a-5ceb-460c-a204-c1c3969c6d62"
ASSIGNMENT_NAME="enforce-tag-policy"
TAG_NAME="Environment"
TAG_VALUE="Production"
TIMESTAMP="2025-06-10 12:50:16"
AUTHOR="GEP-V"

# ==========================================================================
# FUNCTIONS
# ==========================================================================
function log() {
  echo "$(date +"%Y-%m-%d %H:%M:%S") - $1"
}

function error_exit() {
  log "ERROR: $1"
  exit 1
}

function verify_policy_assignment() {
  log "Verifying policy assignment..."
  SUBSCRIPTION_ID=$(az account show --query id -o tsv)
  SCOPE="/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP"
  
  POLICY_CHECK=$(az policy assignment show --name $ASSIGNMENT_NAME --scope $SCOPE 2>/dev/null || echo "")
  
  if [ -z "$POLICY_CHECK" ]; then
    error_exit "Policy assignment verification failed. The policy was not found."
  else
    PARAM_CHECK=$(echo $POLICY_CHECK | jq -r '.parameters | has("tagName") and has("tagValue")')
    if [ "$PARAM_CHECK" != "true" ]; then
      error_exit "Policy assignment verification failed. Missing required parameters."
    else
      log "✅ Policy assignment verified successfully with all required parameters."
    fi
  fi
}

# ==========================================================================
# MAIN EXECUTION
# ==========================================================================
log "Starting Azure policy deployment script"
log "Created: $TIMESTAMP"
log "Author: $AUTHOR"
log "Resource Group: $RESOURCE_GROUP"
log "Policy Definition ID: $POLICY_DEF_ID"
log "Assignment Name: $ASSIGNMENT_NAME"

# Verify Azure CLI is installed
if ! command -v az &> /dev/null; then
  error_exit "Azure CLI is not installed. Please install it first."
fi

# Verify logged in to Azure
ACCOUNT=$(az account show 2>/dev/null || echo "")
if [ -z "$ACCOUNT" ]; then
  log "Not logged in to Azure. Attempting to log in..."
  az login || error_exit "Failed to log in to Azure."
fi

# Get subscription ID
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
SCOPE="/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP"

# Verify the resource group exists
log "Verifying resource group exists..."
RG_CHECK=$(az group show --name $RESOURCE_GROUP 2>/dev/null || echo "")
if [ -z "$RG_CHECK" ]; then
  log "Resource group does not exist. Creating it now..."
  az group create --name $RESOURCE_GROUP --location $LOCATION || error_exit "Failed to create resource group."
fi

# Delete any existing policy assignment with this name
log "Checking for existing policy assignment..."
EXISTING_POLICY=$(az policy assignment show --name $ASSIGNMENT_NAME --scope $SCOPE 2>/dev/null || echo "")
if [ -n "$EXISTING_POLICY" ]; then
  log "Existing policy assignment found. Deleting it..."
  az policy assignment delete --name $ASSIGNMENT_NAME --scope $SCOPE || log "Warning: Failed to delete existing policy assignment."
fi

# Create properly formatted JSON for policy parameters - USE PARAMETERS FILE
log "Creating policy parameters file..."
cat > policy-params.json << EOF
{
  "tagName": {
    "value": "$TAG_NAME"
  },
  "tagValue": {
    "value": "$TAG_VALUE"
  }
}
EOF

log "Parameters file content:"
cat policy-params.json

log "Starting Bicep deployment with proper parameters..."

# Create the deployment using the Bicep template with parameters file
DEPLOYMENT_RESULT=$(az deployment group create \
  --resource-group $RESOURCE_GROUP \
  --name $DEPLOYMENT_NAME \
  --template-file $BICEP_FILE \
  --parameters assignmentName=$ASSIGNMENT_NAME \
              policyDefinitionId=$POLICY_DEF_ID \
              policyDescription="Enforces $TAG_NAME tag with value $TAG_VALUE on all resources" \
              displayName="Require $TAG_NAME Tag" \
              policyParameters=@policy-params.json \
              enforcementMode="Default" \
              useIdentity=false \
  --verbose)

if [ $? -ne 0 ]; then
  error_exit "Bicep deployment failed. Check the error messages above."
fi

log "Bicep deployment completed successfully."

# Verify the policy assignment
verify_policy_assignment

# Get the policy assignment ID
POLICY_ID=$(az policy assignment show --name $ASSIGNMENT_NAME --scope $SCOPE --query id -o tsv)
log "Policy Assignment ID: $POLICY_ID"

log "===================================================="
log "DEPLOYMENT SUMMARY"
log "===================================================="
log "Timestamp: $TIMESTAMP"
log "Author: $AUTHOR"
log "Resource Group: $RESOURCE_GROUP"
log "Policy Definition: $POLICY_DEF_ID"
log "Policy Assignment: $ASSIGNMENT_NAME"
log "Parameters:"
log "  Tag Name: $TAG_NAME"
log "  Tag Value: $TAG_VALUE"
log "===================================================="
log "✅ Deployment completed successfully."