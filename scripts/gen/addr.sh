#!/bin/bash

# Info : Generate a payment and stake address.
#      : An address consists of two parts: the PAYMENT_ADDR and the STAKE_ADDR.
#      : Expects env with set variables.
# Use  : cd $NODE_HOME
#      : scripts/gen/addr.sh <sanchonet | preview | preprod | mainnet>

source "$(dirname "$0")/../../networks/${1:-"preview"}/env"

cardano-cli stake-address build \
    --stake-verification-key-file $STAKE_VKEY \
    --out-file $STAKE_ADDR \
    $NETWORK_ARG

cardano-cli address build \
    --payment-verification-key-file $PAYMENT_VKEY \
    --stake-verification-key-file $STAKE_VKEY \
    --out-file $PAYMENT_ADDR \
    $NETWORK_ARG
    
echo Payment addr: ${PAYMENT_ADDR}
echo Stake addr: ${STAKE_ADDR}
