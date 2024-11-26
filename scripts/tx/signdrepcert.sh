#!/bin/bash
# Usage: scripts/tx/signdrepcert.sh
#
# Info:
#
#   - Sign a DRep registration certificate transaction

source "$(dirname "$0")/../../env"
source "$(dirname "$0")/../common.sh"
outputPath=$NETWORK_PATH/temp

$CNCLI conway transaction sign \
    $NETWORK_ARG \
    --tx-body-file $outputPath/tx.raw \
    --signing-key-file $PAYMENT_KEY \
    --signing-key-file $DREP_KEY \
    --out-file $outputPath/tx.signed

rm $outputPath/tx.raw
print 'TX' "File output: ${outputPath}/tx.signed" $green
