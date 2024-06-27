#!/bin/bash

source "$(dirname "$0")/../common/common.sh"
help 8 1 ${@} || exit
source "$(dirname "$0")/../../networks/${1}/env"

inputFile="${2:-"metadata/metadata.json"}"
outputFile="${3:-"metadata/metadataHash.txt"}"

cardano-cli stake-pool metadata-hash --pool-metadata-file "${inputFile}" > "${outputFile}"
