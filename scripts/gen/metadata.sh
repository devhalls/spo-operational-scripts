#!/bin/bash

# Info : Generate pool metadata hash file.
#      : Outputs file name metadataHash.txt containing the metadata hash.
# Use  : cd $NODE_HOME
#      : scripts/metadata.sh

export $(xargs < env)
NETWORK_PATH=${NODE_HOME}/networks/${NODE_NETWORK}
FILE="${1:-"metadata/metadata.json"}"
OUTPUT_FILE="${2:-"metadata/metadataHash.txt"}"

# Generate the hash
cardano-cli stake-pool metadata-hash --pool-metadata-file "${FILE}" > "${OUTPUT_FILE}"
