#!/bin/bash

# Info : Tail the cardano node service logs.
# Use  : cd $NODE_HOME
#      : scripts/watch.sh <sanchonet | preview | preprod | mainnet>

network="${1:-"preview"}"

journalctl -u cardano-node-$network.service -f -o cat