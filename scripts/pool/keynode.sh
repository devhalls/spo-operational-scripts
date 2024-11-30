#!/bin/bash
# Usage: scripts/pool/keynode.sh
#
# Info:
#
#   - Generate node key pair and node counter

source "$(dirname "$0")/../../env"
source "$(dirname "$0")/../common.sh"
exitIfNotCold

$CNCLI conway node key-gen \
    --cold-verification-key-file $NODE_VKEY \
    --cold-signing-key-file $NODE_KEY \
    --operational-certificate-issue-counter $NODE_COUNTER
