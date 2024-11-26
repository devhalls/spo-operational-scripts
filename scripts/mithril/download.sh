#!/bin/bash
# Usage: scripts/mithril/install/download.sh
#
# Info:
#
#   - Download the Mithril client, signer and relay

source "$(dirname "$0")/../../../env"
source "$(dirname "$0")/../../common.sh"

mkdir -p downloads
wget -O downloads/$MITHRIL_REMOTE_NAME $MITHRIL_REMOTE
tar -xvzf downloads/$MITHRIL_REMOTE_NAME -C downloads
cp -a downloads/mithril-signer $BIN_PATH/mithril-signer
cp -a downloads/mithril-relay $BIN_PATH/mithril-relay
cp -a downloads/mithril-client $BIN_PATH/mithril-client
sudo rm -R downloads
chmod +x -R $BIN_PATH


