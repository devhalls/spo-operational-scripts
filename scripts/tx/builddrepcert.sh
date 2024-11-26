#!/bin/bash
# Usage: scripts/pool/builddrepcert.sh <lovelace>
#
# Info:
#
#   - Build DRep certificate raw transaction

source "$(dirname "$0")/../../env"
source "$(dirname "$0")/../common.sh"

$CNCLI conway transaction build \
  $NETWORK_ARG --socket-path $NETWORK_SOCKET_PATH \
  --tx-in $($CNCLI query utxo --address $(< $PAYMENT_ADDR) $NETWORK_ARG --socket-path $NETWORK_SOCKET_PATH --output-json | jq -r 'keys[0]') \
  --change-address $(< $PAYMENT_ADDR) \
  --certificate-file $DREP_CERT  \
  --witness-override 2 \
  --out-file $NETWORK_PATH/temp/tx.raw
