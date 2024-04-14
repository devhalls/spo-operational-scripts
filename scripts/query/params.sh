#!/bin/bash

# Info : Query params.json for passed FIELD value.
#      : Expects env with set variables.
# Use  : cd $NODE_HOME
#      : scripts/query/params.sh <FIELD> <sanchonet | preview | preprod | mainnet>

source "$(dirname "$0")/../../networks/${2:-"preview"}/env"

field="${1}"
fieldValue=$(cat $NETWORK_PATH/params.json | jq -r ".$field")

echo $field: ${fieldValue}
