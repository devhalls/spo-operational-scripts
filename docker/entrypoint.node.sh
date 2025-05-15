#!/bin/bash
set -e

echo "[ENTRYPOINT] Start container setup"

if [[ ! -f "$NODE_HOME/env" ]]; then
    cp $NODE_HOME/env.example $NODE_HOME/env
    source $NODE_HOME/env
    $NODE_HOME/scripts/node.sh install
    if [ "$MITHRIL_VERSION" ]; then
        $NODE_HOME/scripts/node.sh mithril download
        $NODE_HOME/scripts/node.sh mithril sync
    fi
else
    echo "[ENTRYPOINT] Skipping install"
fi

echo "[ENTRYPOINT] Open metric endpoints"
if [[ ! -f "$NODE_HOME/cardano-node/config.json" ]]; then
    sed -i $NODE_HOME/cardano-node/config.json -e "s/127.0.0.1/0.0.0.0/g"
fi
if [[ ! -f "$NODE_HOME/cardano-node/config-bp.json" ]]; then
    sed -i $NODE_HOME/cardano-node/config-bp.json -e "s/127.0.0.1/0.0.0.0/g"
fi

echo "[ENTRYPOINT] Starting node_exporter"
nohup node_exporter --web.listen-address=":9100" &

echo "[ENTRYPOINT] Starting node"
$NODE_HOME/scripts/node.sh run
