#!/bin/bash
# Usage: scripts/dbsync/start.sh
#
# Info:
#
#   - Launch a cardano node db-sync.
#   - Assumes node is already running.

source "$(dirname "$0")/../../env"
source "$(dirname "$0")/../common.sh"

PGPASSFILE=config/pgpass-mainnet cardano-db-sync -- \
    --config $NETWORK_PATH/db-sync-config.json \
    --socket-path $NETWORK_SOCKET_PATH \
    --state-dir $NETWORK_PATH/ledger-state \
    --schema-dir schema/
