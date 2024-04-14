#!/bin/bash

# Info : Generate a op node.cert certificate using counter and keys.
#      : Expects env with set variables.
# Use  : cd $NODE_HOME
#      : scripts/gen/certop.sh <START_KES>

export $(xargs < env)
START_KES="${1}"
NETWORK_PATH=${NODE_HOME}/networks/${NODE_NETWORK}
NODE_SKEY=${NETWORK_PATH}/keys/node.skey
KES_VKEY=${NETWORK_PATH}/keys/kes.vkey
NODE_COUNTER=${NETWORK_PATH}/keys/node.counter
NODE_CERT=${NETWORK_PATH}/keys/node.cert

cardano-cli node issue-op-cert \
    --kes-verification-key-file $KES_VKEY \
    --cold-signing-key-file $NODE_SKEY \
    --operational-certificate-issue-counter $NODE_COUNTER \
    --kes-period $START_KES \
    --out-file $NODE_CERT
