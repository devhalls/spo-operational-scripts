#!/bin/bash

# Info : Create a pool registration certificate.
#      : Expects env with set varibles.
# Use  : cd $NODE_HOME
#      : scripts/gen/certpool.sh <PLEDGE> <COST> <MARGIN> <RELAY_ADDR> <RELAY_IP> <META_URL> <META_HASH>
#      : scripts/gen/certpool.sh 5400000000 170000000 0.01 172.111.179.82 6000 https://upstream.org.uk/assets/poolMetaData.json

export $(xargs < env)
NETWORK_PATH=${NODE_HOME}/networks/${NODE_NETWORK}
NETWORK_ARG=$([[ "$NODE_NETWORK" == "mainnet" ]] && echo "--mainnet" || echo "--testnet-magic 2")

PLEDGE="${1}"
COST="${2}"
MARGIN="${3}"
RELAY_ADDR="${4}"
RELAY_PORT="${5}"
META_URL="${6}"
META_HASH="${7:-$(cat metadata/metadataHash.txt)}"

# Set runtime variables
NODE_KEY=$NETWORK_PATH/keys/node.vkey
VRF_KEY=$NETWORK_PATH/keys/vrf.vkey
STAKE_KEY=$NETWORK_PATH/keys/stake.vkey
OUTPUT=$NETWORK_PATH/keys/pool.cert

cardano-cli stake-pool registration-certificate \
    --cold-verification-key-file $NODE_KEY \
    --vrf-verification-key-file $VRF_KEY \
    --pool-pledge $PLEDGE \
    --pool-cost $COST \
    --pool-margin $MARGIN \
    --pool-reward-account-verification-key-file $STAKE_KEY \
    --pool-owner-stake-verification-key-file $STAKE_KEY \
    $NETWORK_ARG \
    --single-host-pool-relay $RELAY_ADDR \
    --pool-relay-port $RELAY_PORT \
    --metadata-url $META_URL \
    --metadata-hash $META_HASH \
    --out-file $OUTPUT
