#!/bin/bash
# Usage: scripts/install/download.sh
#
# Info:
#
#   - Downloads node pre compiled binaries.
#   - If $NODE_PLATFORM='arm' we download binaries from armada-alliance repositories.
#   - Otherwise we download builds from intersect repositories.

source "$(dirname "$0")/../../env"
source "$(dirname "$0")/../common.sh"

mkdir -p downloads
if [[ $NODE_PLATFORM == 'arm' ]]; then
  print 'INSTALL' "Downloading node binaries"
  remote=$NODE_REMOTE_ARM/$NODE_REMOTE_ARM_NAME.tar.zst
  wget -O downloads/$NODE_REMOTE_ARM_NAME $remote
  tar --zstd -xvf downloads/$NODE_REMOTE_ARM_NAME -C downloads
  cp -a downloads/$NODE_REMOTE_ARM_NAME/. $BIN_PATH/
else
  print 'INSTALL' "Downloading node binaries"
  wget -O downloads/$NODE_DOWNLOAD $NODE_REMOTE
  tar -xvzf downloads/$NODE_DOWNLOAD -C downloads
  rm downloads/$NODE_DOWNLOAD
  cp -a downloads/bin/. $BIN_PATH/
fi
sudo rm -R downloads
chmod +x -R $BIN_PATH

if [[ "$PATH" != *"$HOME/local/bin/"* ]]; then
  sed -i '$ a\export PATH="$PATH:$HOME/local/bin/"' ~/.bashrc
fi
source ~/.bashrc
print 'INSTALL' "Node binaries moved to $BIN_PATH" $green
