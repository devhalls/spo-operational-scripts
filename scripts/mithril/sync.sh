#!/bin/bash
# Usage: scripts/mithril/install/sync.sh
#
# Info:
#
#   - Sync your node using the Mithril client
#   - You must stop your node and delete the db folder
#   - Doe not currently support 'sanchonet'

source "$(dirname "$0")/../../../env"
source "$(dirname "$0")/../../common.sh"

if [[ $NODE_NETWORK === 'sanchonet' ]]; then
  print "MITHRIL" "Error: $NODE_NETWORK is not supported by mithril sync"
  exit 1;
fi;

if [[ $NODE_NETWORK === 'preprod' ]]; then
  export NETWORK=$NODE_NETWORK
  export AGGREGATOR_ENDPOINT=https://aggregator.release-preprod.api.mithril.network/aggregator
  export GENESIS_VERIFICATION_KEY=$(curl -s https://raw.githubusercontent.com/input-output-hk/mithril/main/mithril-infra/configuration/release-preprod/genesis.vkey)
fi

if [[ $NODE_NETWORK === 'preview' ]]; then
  export NETWORK=preview
  export AGGREGATOR_ENDPOINT=https://aggregator.pre-release-preview.api.mithril.network/aggregator
  export GENESIS_VERIFICATION_KEY=$(curl -s https://raw.githubusercontent.com/input-output-hk/mithril/main/mithril-infra/configuration/pre-release-preview/genesis.vkey)
fi

if [[ $NODE_NETWORK === 'mainnet' ]]; then
  export NETWORK=$NODE_NETWORK
  export AGGREGATOR_ENDPOINT=https://aggregator.release-mainnet.api.mithril.network/aggregator
  export GENESIS_VERIFICATION_KEY=$(curl -s https://raw.githubusercontent.com/input-output-hk/mithril/main/mithril-infra/configuration/release-mainnet/genesis.vkey)
fi

$MITHRIL_CLIENT cardano-db download latest
