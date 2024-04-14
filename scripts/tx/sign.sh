#!/bin/bash

# Info : Signs a raw transaction file then delete it.
#      : Expects env with set variables.
# Use  : cd $NODE_HOME
#      : scripts/tx/sign.sh <sanchonet | preview | preprod | mainnet>

source "$(dirname "$0")/../../networks/${1:-"preview"}/env"

outputPath=${NODE_HOME}/temp

cardano-cli transaction sign \
    --tx-body-file $outputPath/tx.raw \
    --signing-key-file $PAYMENT_KEY \
    $NETWORK_ARG \
    --out-file $outputPath/tx.signed

rm $outputPath/tx.raw

echo File output: ${outputPath}/tx.signed
