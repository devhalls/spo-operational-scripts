#!/bin/bash

# Info : Calculate the KES period.
#      : Expects env with set varibles.
# Use  : cd $NODE_HOME
#      : scripts/query/kes.sh <sanchonet | preview | preprod | mainnet>

source "$(dirname "$0")/../../networks/${1:-"preview"}/env"

slotsPerKESPeriod=$(cat $NETWORK_PATH/shelley-genesis.json | jq -r '.slotsPerKESPeriod')
slotNo=$(cardano-cli query tip $NETWORK_ARG | jq -r '.slot')
kesPeriod=$((${slotNo} / ${slotsPerKESPeriod}))

echo Slots per KES period: ${slotsPerKESPeriod}
echo Current slot: ${slotNo}
echo KES start epriod: ${kesPeriod}
