#!/bin/bash
# Usage: scripts/stop.sh
#
# Info:
#
#   - Stops the cardano node service.

source "$(dirname "$0")/../env"
source "$(dirname "$0")/common.sh"

sudo systemctl stop "${NETWORK_SERVICE}"
print 'STOP' "Node service ${NETWORK_SERVICE} stopped"
