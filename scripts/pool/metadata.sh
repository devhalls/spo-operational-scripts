#!/bin/bash
# Usage: scripts/pool/metadata.sh
#
# Info:
#
#   - Generate vthe metadata hash from your metadata.json file

source "$(dirname "$0")/../../env"
source "$(dirname "$0")/../common.sh"
inputFile="metadata/metadata.json"
outputFile="metadata/metadataHash.txt"

$CNCLI conway stake-pool metadata-hash --pool-metadata-file "${inputFile}" > "${outputFile}"
