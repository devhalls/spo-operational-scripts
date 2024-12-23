#!/bin/bash
# Usage: scripts/dbsync/install.sh
#
# Info:
#
#   - Downloads node pre compiled binaries.
#   - Starts the db-sync-service.
#   - Only supports $NODE_PLATFORM='linux' and download binaries repositories.

source "$(dirname "$0")/../../env"
source "$(dirname "$0")/../common.sh"

print 'INSTALL' 'Creating db-sync directory and downloading binaries'
mkdir -p $DB_SYNC_PATH
bash download.sh

print 'INSTALL' 'Creating db-sync service'
cp -p services/cardano-db-sync.service services/$DB_SYNC_SERVICE.temp
sed -i services/$NETWORK_SERVICE.temp \
    -e "s|NODE_HOME|$NODE_HOME|g" \
    -e "s|NODE_USER|$NODE_USER|g" \
    -e "s|DB_SYNC_SERVICE|$DB_SYNC_SERVICE|g"
sudo cp -p services/$DB_SYNC_SERVICE.temp $SERVICE_PATH/$DB_SYNC_SERVICE
rm services/$DB_SYNC_SERVICE.temp

sudo systemctl daemon-reload
sudo systemctl enable $DB_SYNC_SERVICE
print 'INSTALL' "DB-sync installed" $green
