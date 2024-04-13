#!/bin/bash

# Info : Create a delegation certificate.
#      : Expects env with set varibles.
# Use  : cd $NODE_HOME
#      : scripts/gen/certdeleg.sh 

export $(xargs < env)
NETWORK_PATH=${NODE_HOME}/networks/${NODE_NETWORK}

cardano-cli stake-address delegation-certificate \
    --stake-verification-key-file $NETWORK_PATH/keys/stake.vkey \
    --cold-verification-key-file $NETWORK_PATH/keys/node.vkey \
    --out-file $NETWORK_PATH/keys/deleg.cert
