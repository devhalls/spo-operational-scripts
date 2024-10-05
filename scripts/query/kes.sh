#!/bin/bash

source "$(dirname "$0")/../../networks/${1}/env"
source "$(dirname "$0")/../common/common.sh"
help 17 1 ${@} || exit

slotsPerKESPeriod=$(cat $NETWORK_PATH/shelley-genesis.json | jq -r '.slotsPerKESPeriod')
slotNo=$(cardano-cli query tip $NETWORK_ARG --socket-path $NETWORK_SOCKET_PATH | jq -r '.slot')
kesPeriod=$((${slotNo} / ${slotsPerKESPeriod}))

print 'KES' "Slots per period: ${slotsPerKESPeriod}"
print 'KES' "Current slot: ${slotNo}"
print 'KES' "Start period: ${kesPeriod}"
