#!/bin/bash
# Usage: scripts/pool/keystake.sh
#
# Info:
#
#   - Generates your stake keys

source "$(dirname "$0")/../../env"
source "$(dirname "$0")/../common.sh"

$CNCLI conway stake-address key-gen \
    --verification-key-file $STAKE_VKEY \
    --signing-key-file $STAKE_KEY
