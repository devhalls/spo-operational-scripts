#!/bin/bash
# Usage: scripts/watch.sh
#
# Info:
#
#   - Watch the node service logs using journalctl.

source "$(dirname "$0")/../env"
source "$(dirname "$0")/common.sh"

journalctl -u $NETWORK_SERVICE -f -o cat
