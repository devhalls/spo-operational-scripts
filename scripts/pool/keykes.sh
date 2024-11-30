#!/bin/bash
# Usage: scripts/pool/keykes.sh
#
# Info:
#
#   - Generates your KES keys
#   - Should be ran on the block producer

source "$(dirname "$0")/../../env"
source "$(dirname "$0")/../common.sh"
exitIfNotCold

$CNCLI conway node key-gen-KES \
    --verification-key-file $KES_VKEY \
    --signing-key-file $KES_KEY
