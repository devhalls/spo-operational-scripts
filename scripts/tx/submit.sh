#!/bin/bash
# Usage: scripts/tx/submit.sh
#
# Info:
#
#   - Submit a signed transaction

source "$(dirname "$0")/../../env"
source "$(dirname "$0")/../common.sh"
file=${1:-'tx.signed'}
outputPath=$NETWORK_PATH/temp

$CNCLI conway transaction submit \
    --tx-file $outputPath/$file \
    --socket-path $NETWORK_SOCKET_PATH \
    $NETWORK_ARG

rm $outputPath/$file
