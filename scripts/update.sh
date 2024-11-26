#!/bin/bash
# Usage: scripts/update.sh
#
# Info:
#
#   - Cardano node update script.

source "$(dirname "$0")/../env"
source "$(dirname "$0")/common.sh"

bash scripts/stop.sh

if [[ $NODE_BUILD == 1 ]]; then
  bash scripts/install/download.sh || exit 1
elif [[ $NODE_BUILD == 2 ]]; then
  bash scripts/install/build.sh || exit 1
fi

bash scripts/restart.sh

$CNNODE --version
$CNCLI --version
print 'UPDATE' "Node updated and restarted" $green
