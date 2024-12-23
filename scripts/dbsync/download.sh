#!/bin/bash
# Usage: scripts/dbsync/download.sh
#
# Info:
#
#   - Downloads node pre compiled binaries.
#   - Only supports $NODE_PLATFORM='linux' and download binaries repositories.

source "$(dirname "$0")/../../env"
source "$(dirname "$0")/../common.sh"

relativeDir=../../../$DB_SYNC_REMOTE_NAME

mkdir -p downloads $relativeDir

if [[ $NODE_PLATFORM == 'linux' ]]; then
  print 'INSTALL' "Downloading node binaries"
  wget -O downloads/$DB_SYNC_REMOTE_NAME $DB_SYNC_REMOTE/$DB_SYNC_REMOTE_NAME.tar.gz
  tar --zstd -xvf downloads/$DB_SYNC_REMOTE_NAME -C downloads
  cp -a downloads/$DB_SYNC_REMOTE_NAME/. $BIN_PATH/
  sudo rm -R downloads
  chmod +x -R $BIN_PATH
  $DB_SYNC_NAME --version
  print 'INSTALL' "Node binaries moved to $BIN_PATH" $green
else
  print 'ERROR' "Downloading node binaries we only support linux NODE_PLATFORM" $red
fi
