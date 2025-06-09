#!/bin/bash
# Script to register all required Azure resource providers
# Created: 2025-06-09 23:20:54
# Author: GEP-V

# Set subscription
SUBSCRIPTION_ID=$1

echo "Registering required Azure resource providers in subscription $SUBSCRIPTION_ID..."

# List of providers required for the landing zone
PROVIDERS=(
  "Microsoft.Insights"
  "Microsoft.OperationalInsights"
  "Microsoft.Network"
  "Microsoft.Storage"
  "Microsoft.Compute"
  "Microsoft.Authorization"
  "Microsoft.Resources"
  "Microsoft.PolicyInsights"
)

# Register each provider
for PROVIDER in "${PROVIDERS[@]}"
do
  echo "Registering provider: $PROVIDER"
  az provider register --namespace $PROVIDER --subscription $SUBSCRIPTION_ID
done

# Wait for registration to complete (focus on Insights since that's our issue)
echo "Waiting for Microsoft.Insights registration to complete..."
REGISTERED="no"
MAX_ATTEMPTS=30
ATTEMPT=1

while [ "$REGISTERED" != "Registered" ] && [ $ATTEMPT -le $MAX_ATTEMPTS ]
do
  echo "Checking registration status (attempt $ATTEMPT of $MAX_ATTEMPTS)..."
  REGISTERED=$(az provider show --namespace Microsoft.Insights --query "registrationState" -o tsv --subscription $SUBSCRIPTION_ID)
  echo "Microsoft.Insights status: $REGISTERED"
  
  if [ "$REGISTERED" != "Registered" ]; then
    echo "Waiting 10 seconds..."
    sleep 10
    ATTEMPT=$((ATTEMPT + 1))
  fi
done

if [ "$REGISTERED" == "Registered" ]; then
  echo "Microsoft.Insights provider successfully registered"
else
  echo "WARNING: Microsoft.Insights registration did not complete in the allotted time"
  echo "You may need to wait longer for the registration to complete before configuring diagnostics"
fi

echo "Resource provider registration process completed"