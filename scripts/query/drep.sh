#!/bin/bash
# Usage: scripts/query/drep.sh
#
# Info:
#
#   - Query the dreps-state for all DReps

source "$(dirname "$0")/../../env"
source "$(dirname "$0")/../common.sh"

$CNCLI conway query drep-state --all-dreps $NETWORK_ARG \
  --socket-path $NETWORK_SOCKET_PATH
