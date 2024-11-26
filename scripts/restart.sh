#!/bin/bash
# Usage: scripts/restart.sh
#
# Info:
#
#   - Restarts the cardano node service.

source "$(dirname "$0")/../env"
source "$(dirname "$0")/common.sh"

sudo systemctl restart "${NETWORK_SERVICE}"
print 'RESTART' "Node service ${NETWORK_SERVICE} restarted"
