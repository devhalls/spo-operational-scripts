#!/bin/bash
# Usage: scripts/query/tip.sh
#
# Info:
#
#   - Query the chain tip and shelley-genesis.json for the correct KES start period
#   - Node must be fully synced

source "$(dirname "$0")/../../env"
source "$(dirname "$0")/../common.sh"

slotsPerKESPeriod=$(cat $NETWORK_PATH/shelley-genesis.json | jq -r '.slotsPerKESPeriod')
slotNo=$($CNCLI conway query tip $NETWORK_ARG --socket-path $NETWORK_SOCKET_PATH | jq -r '.slot')
kesPeriod=$((${slotNo} / ${slotsPerKESPeriod}))

print 'KES' "Slots per period: ${slotsPerKESPeriod}"
print 'KES' "Current slot: ${slotNo}"
print 'KES' "KES period: ${kesPeriod}"
