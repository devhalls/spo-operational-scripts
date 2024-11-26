#!/bin/bash
# Usage: scripts/install/configs.sh
#
# Info:
#
#   - Downloads node and network configuration files.
#   - Files saved to $NETWORK_PATH.

source "$(dirname "$0")/../../env"
source "$(dirname "$0")/../common.sh"

print 'INSTALL' "Downloading config files for $NODE_NETWORK"
for C in ${CONFIG_DOWNLOADS[@]}; do
  wget -O $NETWORK_PATH/$C $CONFIG_REMOTE/$C
done
print 'INSTALL' "Downloaded configs for $NODE_NETWORK" $green
