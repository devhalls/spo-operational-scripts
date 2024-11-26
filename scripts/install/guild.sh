#!/bin/bash
# Usage: scripts/install/download.sh
#
# Info:
#
#   - Downloads guild monitor script to $NETWORK_PATH/scripts.
#   - Replaces env variables with our node configs.

source "$(dirname "$0")/../../env"
source "$(dirname "$0")/../common.sh"

print 'INSTALL' "Downloading guild scripts"
for G in ${GUILD_SCRIPT_DOWNLOADS[@]}; do
    wget -O $NETWORK_PATH/scripts/$G $GUILD_REMOTE/$G
done
chmod +x $NETWORK_PATH/scripts/gLiveView.sh
sed -i $NETWORK_PATH/scripts/env \
    -e "s|\#CONFIG=\"\${CNODE_HOME}\/files\/config.json\"|CONFIG=\"${NETWORK_PATH}\/config.json\"|g" \
    -e "s|\#SOCKET=\"\${CNODE_HOME}\/sockets\/node.socket\"|SOCKET=\"${NETWORK_PATH}\/db\/socket\"|g" \
    -e "s|\#CNODE_PORT=6000|CNODE_PORT=\"${NODE_PORT}\"|g" \
    -e "s|\#CNODEBIN=\"\${HOME}\/.local\/bin\/cardano-node\"|CNODEBIN=\"\${HOME}\/local\/bin\/cardano-node\"|g" \
    -e "s|\#CCLI=\"\${HOME}\/.local\/bin\/cardano-cli\"|CCLI=\"\${HOME}\/local\/bin\/cardano-cli\"|g"
print 'INSTALL' "Downloaded guild scripts" $green
