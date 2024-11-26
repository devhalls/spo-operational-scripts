#!/bin/bash
# Usage: scripts/pool/rotate.sh <startPeriod>
#
# Info:
#
#   - Rotate the pool KES certificate

source "$(dirname "$0")/../../env"
source "$(dirname "$0")/../common.sh"
startPeriod="${1}"

$CNCLI conway node key-gen-KES \
    --verification-key-file $KES_VKEY \
    --signing-key-file $KES_KEY

$CNCLI conway node issue-op-cert \
    --kes-verification-key-file $KES_VKEY \
    --cold-signing-key-file $NODE_KEY \
    --operational-certificate-issue-counter $NODE_COUNTER \
    --kes-period $startPeriod \
    --out-file $NODE_CERT

print 'KES' "Copy node.cert and kes.skey back to your block producer node"
print 'KES' "Then restart your node with scripts/restart.sh"
