#!/bin/bash
# Usage: scripts/pool/keypayment.sh
#
# Info:
#
#   - Generates your payment keys

source "$(dirname "$0")/../../env"
source "$(dirname "$0")/../common.sh"

$CNCLI conway address key-gen \
    --verification-key-file $PAYMENT_VKEY \
    --signing-key-file $PAYMENT_KEY
