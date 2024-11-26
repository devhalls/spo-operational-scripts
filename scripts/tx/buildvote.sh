#!/bin/bash
# Usage: scripts/pool/buildvote.sh <lovelace>
#
# Info:
#
#   - Build transaction including the vote

source "$(dirname "$0")/../../env"
source "$(dirname "$0")/../common.sh"
govActionId=${1}
govActionIndex=${2}
votePath=$NETWORK_PATH/temp/vote.raw

$CNCLI conway transaction build \
  $NETWORK_ARG --socket-path $NETWORK_SOCKET_PATH \
  --tx-in $($CNCLI query utxo --address $(< $PAYMENT_ADDR) $NETWORK_ARG --socket-path $NETWORK_SOCKET_PATH --output-json | jq -r 'keys[0]') \
  --change-address $(< $PAYMENT_ADDR) \
  --vote-file $votePath \
  --witness-override 2 \
  --out-file $NETWORK_PATH/temp/tx.raw

print 'TX' "File output: $NETWORK_PATH/temp/tx.raw" $green
