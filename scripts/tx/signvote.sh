#!/bin/bash
# Usage: scripts/tx/signvote.sh <keyFile 'node.skey' | 'drep.skey' | 'cc-hot.skey'>
#
# Info:
#
#   - Sign a governance action vote

source "$(dirname "$0")/../../env"
source "$(dirname "$0")/../common.sh"
keyFile=${1}
tempPath=$NETWORK_PATH/temp

$CNCLI conway transaction sign --tx-body-file $tempPath/tx.raw \
   --signing-key-file $NETWORK_PATH/keys/$keyFile \
   --signing-key-file $PAYMENT_KEY \
   --out-file $tempPath/tx.signed

rm $tempPath/tx.raw
print 'TX' "File output: $tempPath/tx.signed" $green
