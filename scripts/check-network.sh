#!/usr/bin/env bash
set -euo pipefail

# 👉 Update these if your names differ
CONNECTIVITY_SUB="${CONNECTIVITY_SUBSCRIPTION_ID:-YOUR_CONNECTIVITY_SUB_ID}"
SANDBOX_SUB="${SANDBOX_SUBSCRIPTION_ID:-YOUR_SANDBOX_SUB_ID}"

HUB_RG="rg-connectivity-hub"
HUB_VNET="vnet-hub"

SANDBOX_RG="rg-sandbox-network"
SANDBOX_VNET="vnet-sandbox"

echo
echo "🔎  Verifying Hub VNet in Connectivity subscription..."
az account set --subscription "$CONNECTIVITY_SUB"
az network vnet show \
  --resource-group "$HUB_RG" \
  --name "$HUB_VNET" \
  --query "{ id:id, addressSpace:addressSpace.addressPrefixes }" \
  -o json
echo "✅  Hub VNet exists and returned above."

echo
echo "🔎  Verifying Sandbox VNet in Sandbox subscription..."
az account set --subscription "$SANDBOX_SUB"
az network vnet show \
  --resource-group "$SANDBOX_RG" \
  --name "$SANDBOX_VNET" \
  --query "{ id:id, addressSpace:addressSpace.addressPrefixes, subnets:subnets[*].name }" \
  -o json
echo "✅  Sandbox VNet exists and returned above."

echo
echo "🔎  Listing peerings on Sandbox spoke (should include 'spoke-to-hub')"
az network vnet peering list \
  --subscription "$SANDBOX_SUB" \
  --resource-group "$SANDBOX_RG" \
  --vnet-name "$SANDBOX_VNET" \
  --query "[].{name:name, state:peeringState, remote:remoteVirtualNetwork.id}" \
  -o table

echo
echo "🔎  Listing peerings on Hub VNet (should include 'hub-to-spoke')"
az account set --subscription "$CONNECTIVITY_SUB"
az network vnet peering list \
  --resource-group "$HUB_RG" \
  --vnet-name "$HUB_VNET" \
  --query "[].{name:name, state:peeringState, remote:remoteVirtualNetwork.id}" \
  -o table

echo
echo "📡  Optional: test connectivity via Network Watcher (if enabled)"
# Replace these NIC and IP values with an actual VM NIC in each VNet if you want a true test
# az network watcher test-connectivity \
#   --source-resource /subscriptions/$SANDBOX_SUB/resourceGroups/$SANDBOX_RG/providers/Microsoft.Compute/virtualMachines/sandbox-vm1 \
#   --dest-address 10.0.0.4 \
#   --dest-port 22

echo
echo "🎉  All checks completed."
