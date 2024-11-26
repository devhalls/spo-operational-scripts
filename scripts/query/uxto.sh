#!/bin/bash
# Usage: scripts/query/uxto.sh
#
# Info:
#
#   - Query uxto for address defaults to payment.addr address

source "$(dirname "$0")/../../env"
source "$(dirname "$0")/../common.sh"
address=${1:-"$PAYMENT_ADDR"}

$CNCLI conway query utxo --address $(cat $address) $NETWORK_ARG --socket-path $NETWORK_SOCKET_PATH
