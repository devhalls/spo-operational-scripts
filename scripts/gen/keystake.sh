#!/bin/bash

# Info : Generate payment and stake key pairs.
#      : Expects env with set variables.
# Use  : cd $NODE_HOME
#      : scripts/gen/keystake.sh

export $(xargs < env)
NETWORK_PATH=${NODE_HOME}/networks/${NODE_NETWORK}
PAYMENT_VKEY=${NETWORK_PATH}/keys/payment.vkey
PAYMENT_SKEY=${NETWORK_PATH}/keys/payment.skey
STAKE_VKEY=${NETWORK_PATH}/keys/stake.vkey
STAKE_SKEY=${NETWORK_PATH}/keys/stake.skey

cardano-cli address key-gen \
    --verification-key-file $PAYMENT_VKEY \
    --signing-key-file $PAYMENT_SKEY
    
cardano-cli stake-address key-gen \
    --verification-key-file $STAKE_VKEY \
    --signing-key-file $STAKE_SKEY
