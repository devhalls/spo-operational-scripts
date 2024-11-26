#!/bin/bash
# Usage: scripts/pool/keynode.sh
#
# Info:
#
#   - Generate a payment and stake address
#   - An address consists of two parts: the PAYMENT_ADDR and the STAKE_ADDR

source "$(dirname "$0")/../../env"
source "$(dirname "$0")/../common.sh"

$CNCLI conway stake-address build \
    --stake-verification-key-file $STAKE_VKEY \
    --out-file $STAKE_ADDR \
    $NETWORK_ARG

$CNCLI conway address build \
    --payment-verification-key-file $PAYMENT_VKEY \
    --stake-verification-key-file $STAKE_VKEY \
    --out-file $PAYMENT_ADDR \
    $NETWORK_ARG
    
print 'ADDRESS' "Payment address: $PAYMENT_ADDR" $green
print 'ADDRESS' "Stake address: $STAKE_ADDR" $green
