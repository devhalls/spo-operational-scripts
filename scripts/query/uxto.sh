#!/bin/bash

# Info : Query uxto for address defaults to payment.addr address.
#      : Expects env with set varibles.
# Use  : cd $NODE_HOME
#      : scripts/genquery/uxto.sh <ADDR> <sanchonet | preview | preprod | mainnet>

source "$(dirname "$0")/../../networks/${2:-"preview"}/env"

addr=${1:-"$NETWORK_PATH/keys/payment.addr"}

cardano-cli query utxo --address $(cat $addr) $NETWORK_ARG