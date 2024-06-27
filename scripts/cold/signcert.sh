#!/bin/bash

source "$(dirname "$0")/../common/common.sh"
help 13 1 ${@} || exit
source "$(dirname "$0")/../../networks/${1}/env"

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
