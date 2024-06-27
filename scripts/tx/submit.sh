#!/bin/bash

source "$(dirname "$0")/../common/common.sh"
help 12 1 ${@} || exit
source "$(dirname "$0")/../../networks/${1}/env"

outputPath=${NODE_HOME}/temp

cardano-cli transaction submit \
    --tx-file $outputPath/tx.signed \
    --socket-path $NETWORK_SOCKET_PATH \
    $NETWORK_ARG

rm $outputPath/tx.signed
