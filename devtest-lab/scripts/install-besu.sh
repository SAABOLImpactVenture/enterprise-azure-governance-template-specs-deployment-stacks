#!/usr/bin/env bash
#
# install-besu.sh
#
# Installs Hyperledger Besu, initializes it with a genesis file,
# and starts it with the provided IBFT parameters.
#
# Usage:
#   ./install-besu.sh \
#     <GENESIS_URI> \
#     <CHAIN_ID> \
#     <GAS_LIMIT> \
#     "<BOOTNODES>" \
#     <RPC_ENABLED>
#

set -euo pipefail

GENESIS_URI="$1"       # e.g. https://mystorage.blob.core.windows.net/genesis.json
CHAIN_ID="$2"          # e.g. 10
GAS_LIMIT="$3"         # hex or decimal, e.g. 0x1C9C380
BOOTNODES="$4"         # comma-separated enode URLs
RPC_ENABLED="$5"       # true|false

echo "==> Updating OS and installing dependencies…"
apt-get update -qq
apt-get install -y wget apt-transport-https gnupg2

echo "==> Adding Besu repository…"
wget -qO - https://dl.bintray.com/hyperledger-org/besu-deb/besu2.x.key | apt-key add -
echo "deb [arch=amd64] https://dl.bintray.com/hyperledger-org/besu-deb stable main" \
     | tee /etc/apt/sources.list.d/besu.list
apt-get update -qq
apt-get install -y besu

echo "==> Downloading genesis file and initializing…"
mkdir -p /var/lib/besu
curl -fsSL "$GENESIS_URI" -o /var/lib/besu/genesis.json
besu --data-path=/var/lib/besu init /var/lib/besu/genesis.json

echo "==> Launching Besu…"
cmd=(besu
  --data-path=/var/lib/besu
  --network-id="$CHAIN_ID"
  --miner-enabled=false
  --min-gas-price=0
  --genesis-file=/var/lib/besu/genesis.json
  --nodes-key-file=/var/lib/besu/keys/nodeKey
  --bootnodes="$BOOTNODES"
  --rpc-http-host=0.0.0.0
  --rpc-http-port=8545
)

if [[ "$RPC_ENABLED" == "true" ]]; then
  cmd+=(--rpc-http-enabled)
fi

# Run in background and log to file
nohup "${cmd[@]}" > /var/log/besu.log 2>&1 &

echo "==> Besu started, logging to /var/log/besu.log"
