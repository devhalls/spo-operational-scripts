#!/bin/bash

# Info : Generate KES key pair.
#      : Expects env with set variables.
# Use  : cd $NODE_HOME
#      : scripts/gen/keykes.sh

export $(xargs < env)
NETWORK_PATH=${NODE_HOME}/networks/${NODE_NETWORK}
KES_VKEY=${NETWORK_PATH}/keys/kes.vkey
KES_SKEY=${NETWORK_PATH}/keys/kes.skey

cardano-cli node key-gen-KES \
    --verification-key-file $KES_VKEY \
    --signing-key-file $KES_SKEY
