#!/usr/bin/env bash
set -euo pipefail

# These must be set in the environment (e.g. via GitHub Secrets in your workflow)
CONNECTIVITY_SUB="${CONNECTIVITY_SUBSCRIPTION_ID:?CONNECTIVITY_SUBSCRIPTION_ID is not set}"
SANDBOX_SUB="${SANDBOX_SUBSCRIPTION_ID:?SANDBOX_SUBSCRIPTION_ID is not set}"

# Your resource group + VNet names
HUB_RG="rg-connectivity-hub"
HUB_VNET="vnet-hub"

SANDBOX_RG="rg-sandbox-network"
SANDBOX_VNET="vnet-sandbox"

echo
echo "🔎  Verifying Hub VNet in Connectivity subscription ($CONNECTIVITY_SUB)..."
az account set --subscription "$CONNECTIVITY_SUB"
az network vnet show \
  --resource-group "$HUB_RG" \
  --name "$HUB_VNET" \
  --query "{ id:id, addressSpace:addressSpace.addressPrefixes }" \
  -o json

echo
echo "🔎  Verifying Sandbox VNet in Sandbox subscription ($SANDBOX_SUB)..."
az account set --subscription "$SANDBOX_SUB"
az network vnet show \
  --resource-group "$SANDBOX_RG" \
  --name "$SANDBOX_VNET" \
  --query "{ id:id, addressSpace:addressSpace.addressPrefixes, subnets:subnets[*].name }" \
  -o json

echo
echo "🔎  Listing peerings on Sandbox VNet (should include 'spoke-to-hub'):"
az network vnet peering list \
  --subscription "$SANDBOX_SUB" \
  --resource-group "$SANDBOX_RG" \
  --vnet-name "$SANDBOX_VNET" \
  --query "[].{name:name, state:peeringState, remote:remoteVirtualNetwork.id}" \
  -o table

echo
echo "🔎  Listing peerings on Hub VNet (should include 'hub-to-spoke'):"
az account set --subscription "$CONNECTIVITY_SUB"
az network vnet peering list \
  --resource-group "$HUB_RG" \
  --vnet-name "$HUB_VNET" \
  --query "[].{name:name, state:peeringState, remote:remoteVirtualNetwork.id}" \
  -o table

echo
echo "✅  Network checks complete."
