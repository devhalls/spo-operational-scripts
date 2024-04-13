#!/bin/bash

# Info : Generate node key pair and node counter.
#      : Expects env with set varibles.
# Use  : cd $NODE_HOME
#      : scripts/gen/keynode.sh

export $(xargs < env)
NETWORK_PATH=${NODE_HOME}/networks/${NODE_NETWORK}
NODE_VKEY=${NETWORK_PATH}/keys/node.vkey
NODE_SKEY=${NETWORK_PATH}/keys/node.skey
NODE_COUNTER=${NETWORK_PATH}/keys/node.counter

cardano-cli node key-gen \
    --cold-verification-key-file $NODE_VKEY \
    --cold-signing-key-file $NODE_SKEY \
    --operational-certificate-issue-counter $NODE_COUNTER
