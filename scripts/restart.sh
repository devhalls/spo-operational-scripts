#!/bin/bash

# Info : Restart the cardano node service.
# Use  : cd $NODE_HOME
#      : scripts/restart.sh <sanchonet | preview | preprod | mainnet>

network="${1:-"preview"}"

sudo systemctl restart cardano-node-"${network}"

echo "Node service cardano-node-${network} re-started"