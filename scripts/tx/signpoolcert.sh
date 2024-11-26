#!/bin/bash
# Usage: scripts/tx/signpoolcert.sh
#
# Info:
#
#   - Sign a Pool registration certificate transaction

source "$(dirname "$0")/../../env"
source "$(dirname "$0")/../common.sh"
outputPath=$NETWORK_PATH/temp

$CNCLI conway transaction sign \
    --tx-body-file $outputPath/tx.raw \
    --signing-key-file $PAYMENT_KEY \
    --signing-key-file $NODE_KEY \
    --signing-key-file $STAKE_KEY \
    $NETWORK_ARG \
    --out-file $outputPath/tx.signed

rm $outputPath/tx.raw
print 'TX' "File output: ${outputPath}/tx.signed" $green
