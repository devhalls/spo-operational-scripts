#!/bin/bash

# Info : Generate stake.cert certificate file.
#      : Expects env with set variables.
# Use  : cd $NODE_HOME
#      : scripts/gen/regcert.sh

export $(xargs < env)
START_KES="${1}"
NETWORK_PATH=${NODE_HOME}/networks/${NODE_NETWORK}
STAKE_VKEY=${NETWORK_PATH}/keys/stake.vkey
STAKE_CERT=${NETWORK_PATH}/keys/stake.cert

cardano-cli stake-address registration-certificate \
    --stake-verification-key-file $STAKE_VKEY \
    --out-file $STAKE_CERT
