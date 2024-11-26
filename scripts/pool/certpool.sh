#!/bin/bash
# Usage: scripts/pool/certpool.sh <pledge>, <cost>, <margin>, <relayAddr>, <relayPort>, <metaUrl>, <metaHash>
#
# Info:
#
#   - Register a single relay pool and generate a pool.cert certificate

source "$(dirname "$0")/../../env"
source "$(dirname "$0")/../common.sh"
pledge="${1}"
cost="${2}"
margin="${3}"
relayAddr="${4}"
relayPort="${5}"
metaUrl="${6}"
metaHash="${7:-$(cat metadata/metadataHash.txt)}"

$CNCLI conway stake-pool registration-certificate \
    --cold-verification-key-file $NODE_VKEY \
    --vrf-verification-key-file $VRF_VKEY \
    --pool-pledge $pledge \
    --pool-cost $cost \
    --pool-margin $margin \
    --pool-reward-account-verification-key-file $STAKE_VKEY \
    --pool-owner-stake-verification-key-file $STAKE_VKEY \
    $NETWORK_ARG \
    --single-host-pool-relay $relayAddr \
    --pool-relay-port $relayPort \
    --metadata-url $metaUrl \
    --metadata-hash $metaHash \
    --out-file $POOL_CERT
