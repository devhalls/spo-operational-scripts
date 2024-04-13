#!/bin/bash

# Info : Signs a raw transaction file with the node and stake keys.
#      : Expects env with set varibles.
# Use  : cd $NODE_HOME
#      : scripts/tx/signcold.sh <sanchonet | preview | preprod | mainnet>

source "$(dirname "$0")/../../networks/${3:-"preview"}/env"

outputPath=${NODE_HOME}/temp

cardano-cli transaction sign \
    --tx-body-file $outputPath/tx.raw \
    --signing-key-file $PAYMENT_KEY \
    --signing-key-file $NODE_KEY \
    --signing-key-file $STAKE_KEY \
    $NETWORK_ARG \
    --out-file $outputPath/tx.signed

rm $outputPath/tx.raw

echo File output: ${outputPath}/tx.signed
