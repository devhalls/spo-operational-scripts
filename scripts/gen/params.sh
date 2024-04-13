#!/bin/bash

# Info : Query and outout the networks protocol params.
#      : Expects env with set varibles.
# Use  : cd $NODE_HOME
#      : scripts/params.sh <OUTPUT_FILE>

export $(xargs < env)
NETWORK_PATH=${NODE_HOME}/networks/${NODE_NETWORK}
NETWORK_ARG=$([[ "$NODE_NETWORK" == "mainnet" ]] && echo "--mainnet" || echo "--testnet-magic 2")
OUTPUT_FILE="${1:-"params.json"}"

# Output the protocal params.
cardano-cli query protocol-parameters \
    $NETWORK_ARG \
    --out-file $NETWORK_PATH/$OUTPUT_FILE

