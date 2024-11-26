#!/bin/bash
# Usage: scripts/query/poolid.sh
#
# Info:
#
#   - COLD NODE; execute on cold node
#   - Runs the pool leader slot check and creates file 'epoch.txt'

source "$(dirname "$0")/../../env"
source "$(dirname "$0")/../common.sh"

$CCLI conway stake-pool id --cold-verification-key-file $NODE_VKEY --output-format hex > $POOL_ID
print "POOL" "ID: $(cat $POOL_ID)" $green
