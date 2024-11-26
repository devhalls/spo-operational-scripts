#!/bin/bash
# Usage: scripts/govern/query.sh <govActionId>
#
# Info:
#
#   - Query the state for the passed govActionId

source "$(dirname "$0")/../../env"
source "$(dirname "$0")/../common.sh"
govActionId=${1}

$CNCLI conway query gov-state $NETWORK_ARG --socket-path $NETWORK_SOCKET_PATH |
jq -r --arg govActionId "$govActionId" '.proposals | to_entries[] | select(.value.actionId.txId | contains($govActionId)) | .value'
