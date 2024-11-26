#!/bin/bash
# Usage: scripts/query/kes.sh
#
# Info:
#
#   - Query the KES info for the node certificate
#   - Shows the tests results for the current certificate and json response

source "$(dirname "$0")/../../env"
source "$(dirname "$0")/../common.sh"

print 'KES' "Current KES state:" $green

$CNCLI conway query kes-period-info $NETWORK_ARG \
  --socket-path $NETWORK_SOCKET_PATH \
  --op-cert-file $NODE_CERT

print 'KES' "Current node counter: " $green
cat $NODE_COUNTER
