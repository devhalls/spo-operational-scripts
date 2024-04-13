#!/bin/bash

# Info : Submit a signed transaction file.
#      : Expects env with set varibles.
# Use  : cd $NODE_HOME
#      : scripts/tx/submit.sh <sanchonet | preview | preprod | mainnet>

source "$(dirname "$0")/../../networks/${1:-"preview"}/env"

outputPath=${NODE_HOME}/temp

cardano-cli transaction submit \
    --tx-file $outputPath/tx.signed \
    $NETWORK_ARG

rm $outputPath/tx.signed