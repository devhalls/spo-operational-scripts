#!/bin/bash
# Usage: scripts/pool/certdeleg.sh
#
# Info:
#
#   - Create a delegation certificate

source "$(dirname "$0")/../../env"
source "$(dirname "$0")/../common.sh"

$CNCLI conway stake-address stake-delegation-certificate \
    --stake-verification-key-file $STAKE_VKEY \
    --cold-verification-key-file $NODE_VKEY \
    --out-file $DELE_CERT
