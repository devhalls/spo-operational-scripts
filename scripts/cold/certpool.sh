#!/bin/bash

source "$(dirname "$0")/../common/common.sh"
help 7 7 ${@} || exit
source "$(dirname "$0")/../../networks/${1}/env"

pledge="${2}"
cost="${3}"
margin="${4}"
relayAddr="${5}"
relayPort="${6}"
metaUrl="${7}"
metaHash="${8:-$(cat metadata/metadataHash.txt)}"

cardano-cli stake-pool registration-certificate \
    --cold-verification-key-file $NODE_KEY \
    --vrf-verification-key-file $VRF_KEY \
    --pool-pledge $pledge \
    --pool-cost $cost \
    --pool-margin $margin \
    --pool-reward-account-verification-key-file $STAKE_KEY \
    --pool-owner-stake-verification-key-file $STAKE_KEY \
    $NETWORK_ARG \
    --single-host-pool-relay $relayAddr \
    --pool-relay-port $relayPort \
    --metadata-url $metaUrl \
    --metadata-hash $metaHash \
    --out-file $POOL_CERT
