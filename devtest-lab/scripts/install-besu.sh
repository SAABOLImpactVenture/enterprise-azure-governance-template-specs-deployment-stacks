#!/usr/bin/env bash
#
# install-besu.sh
#
# Installs Hyperledger Besu, initializes it with a genesis file,
# and starts it with the provided IBFT parameters.
#
# Usage:
#   install-besu.sh \
#     <GENESIS_URI> \
#     <CHAIN_ID> \
#     <GAS_LIMIT> \
#     "<BOOTNODES>" \
#     <RPC_ENABLED>
#

set -euo pipefail

GENESIS_URI="$1"       # e.g. https://mystorage.blob.core.windows.net/genesis.json
CHAIN_ID="$2"          # e.g. 10
GAS_LIMIT="$3"         # e.g. 0x1C9C380
BOOTNODES="$4"         # comma-separated enode URLs
RPC_ENABLED="$5"       # true or false

echo "==> Installing prerequisites…"
# update + install Java, curl, jq, tar
apt-get update -qq
apt-get install -y openjdk-17-jdk-headless wget curl jq tar

echo "==> Fetching Hyperledger Besu latest release…"
# determine latest tag
RELEASE_URL="https://api.github.com/repos/hyperledger/besu/releases/latest"
TAG=$(curl -sSL "$RELEASE_URL" | jq -r .tag_name)
ARTIFACT="besu-${TAG}.tar.gz"
URL="https://github.com/hyperledger/besu/releases/download/${TAG}/${ARTIFACT}"

# download & extract
wget -qO "/tmp/${ARTIFACT}" "$URL"
tar -xzf "/tmp/${ARTIFACT}" -C /opt
ln -sf "/opt/besu-${TAG}/bin/besu" /usr/local/bin/besu

echo "==> Besu version: $(besu --version)"

echo "==> Preparing data directories…"
mkdir -p /var/lib/besu/keys
mkdir -p /var/lib/besu
mkdir -p /var/log/besu

echo "==> Downloading genesis file…"
curl -fsSL "$GENESIS_URI" -o /var/lib/besu/genesis.json

echo "==> Initializing Besu with genesis.json…"
besu --data-path=/var/lib/besu init /var/lib/besu/genesis.json

echo "==> Launching Besu node…"
cmd=(
  besu
  --data-path=/var/lib/besu
  --network-id="$CHAIN_ID"
  --min-gas-price=0
  --genesis-file=/var/lib/besu/genesis.json
  --node-private-key-file=/var/lib/besu/keys/nodekey
  --bootnodes="$BOOTNODES"
  --rpc-http-host=0.0.0.0
  --rpc-http-port=8545
)

if [[ "$RPC_ENABLED" == "true" ]]; then
  cmd+=(--rpc-http-enabled)
else
  cmd+=(--rpc-http-enabled=false)
fi

# start in background
nohup "${cmd[@]}" > /var/log/besu/besu.log 2>&1 &

echo "==> Besu started (chainId=$CHAIN_ID). Logs: /var/log/besu/besu.log"
