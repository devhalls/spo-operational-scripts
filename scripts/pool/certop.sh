#!/bin/bash
# Usage: scripts/pool/certop.sh <kesPeriod>
#
# Info:
#
#   - Generate a op node.cert certificate using counter and keys

source "$(dirname "$0")/../../env"
source "$(dirname "$0")/../common.sh"
kesPeriod="${1}"

$CNCLI conway node issue-op-cert \
    --kes-verification-key-file $KES_VKEY \
    --cold-signing-key-file $NODE_KEY \
    --operational-certificate-issue-counter $NODE_COUNTER \
    --kes-period $kesPeriod \
    --out-file $NODE_CERT
