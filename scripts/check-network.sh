#!/usr/bin/env bash
set -euo pipefail

# ────────────────────────────────────────────────────────────────────────
# 1) Determine your two subscriptions (with sane fallbacks)
# ────────────────────────────────────────────────────────────────────────

if [[ -n "${CONNECTIVITY_SUBSCRIPTION_ID:-}" ]]; then
  CONNECTIVITY_SUB="$CONNECTIVITY_SUBSCRIPTION_ID"
else
  echo "⚠️  CONNECTIVITY_SUBSCRIPTION_ID not set, defaulting to current subscription"
  CONNECTIVITY_SUB=$(az account show --query id -o tsv)
fi

if [[ -n "${SANDBOX_SUBSCRIPTION_ID:-}" ]]; then
  SANDBOX_SUB="$SANDBOX_SUBSCRIPTION_ID"
else
  echo "⚠️  SANDBOX_SUBSCRIPTION_ID not set, defaulting to connectivity subscription"
  SANDBOX_SUB="$CONNECTIVITY_SUB"
fi

echo "🔑 Using Connectivity subscription: $CONNECTIVITY_SUB"
echo "🔑 Using Sandbox subscription:     $SANDBOX_SUB"

# ────────────────────────────────────────────────────────────────────────
# 2) Define your RG & VNet names
# ────────────────────────────────────────────────────────────────────────

HUB_RG="rg-connectivity-hub"
HUB_VNET="vnet-hub"

SANDBOX_RG="rg-sandbox-network"
SANDBOX_VNET="vnet-sandbox"

# ────────────────────────────────────────────────────────────────────────
# 3) Check Hub VNet
# ────────────────────────────────────────────────────────────────────────

echo
echo "🔎  Verifying Hub VNet in Connectivity subscription..."
az account set --subscription "$CONNECTIVITY_SUB"
az network vnet show \
  --resource-group "$HUB_RG" \
  --name "$HUB_VNET" \
  --query "{ id:id, addressSpace:addressSpace.addressPrefixes }" \
  -o json

# ────────────────────────────────────────────────────────────────────────
# 4) Check Sandbox VNet
# ────────────────────────────────────────────────────────────────────────

echo
echo "🔎  Verifying Sandbox VNet in Sandbox subscription..."
az account set --subscription "$SANDBOX_SUB"
az network vnet show \
  --resource-group "$SANDBOX_RG" \
  --name "$SANDBOX_VNET" \
  --query "{ id:id, addressSpace:addressSpace.addressPrefixes, subnets:subnets[*].name }" \
  -o json

# ────────────────────────────────────────────────────────────────────────
# 5) List peerings
# ────────────────────────────────────────────────────────────────────────

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
