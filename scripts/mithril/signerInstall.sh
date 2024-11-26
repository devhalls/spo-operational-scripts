#!/bin/bash

source "$(dirname "$0")/../../env"
source "$(dirname "$0")/../common.sh"
help 21 0 ${@} || exit 1

# Configure mithril env.
sudo mkdir $MITHRIL_HOME
cd $MITHRIL_HOME
sudo bash -c "cat > mithril-signer.env << EOF
KES_SECRET_KEY_PATH=$KES_KEY
OPERATIONAL_CERTIFICATE_PATH=$NODE_CERT
NETWORK=$NODE_NETWORK
AGGREGATOR_ENDPOINT=https://aggregator.release-$NODE_NETWORK.api.mithril.network/aggregator
RUN_INTERVAL=60000
DB_DIRECTORY=$NETWORK_DB_PATH
CARDANO_NODE_SOCKET_PATH=$NETWORK_SOCKET_PATH
CARDANO_CLI_PATH=$CNCLI
DATA_STORES_DIRECTORY=$MITHRIL_HOME/stores
STORE_RETENTION_LIMIT=5
ERA_READER_ADAPTER_TYPE=cardano-chain
ERA_READER_ADAPTER_PARAMS={"address": "addr_test1qpkyv2ws0deszm67t840sdnruqgr492n80g3y96xw3p2ksk6suj5musy6w8lsg3yjd09cnpgctc2qh386rtxphxt248qr0npnx", "verification_key": "5b35352c3232382c3134342c38372c3133382c3133362c34382c382c31342c3138372c38352c3134382c39372c3233322c3235352c3232392c33382c3234342c3234372c3230342c3139382c31332c33312c3232322c32352c3136342c35322c3130322c39312c3132302c3230382c3134375d"}
RELAY_ENDPOINT=$MITHRIL_RELAY
ENABLE_METRICS_SERVER=$MITHRIL_PROMETHEUS
METRICS_SERVER_IP=$METRICS_SERVER_IP
METRICS_SERVER_PORT=$METRICS_SERVER_PORT
EOF"

# Format supervisor service files.
cp -p services/mithril.service services/$MITHRIL_SERVICE.temp
sed -i services/$MITHRIL_SERVICE.temp \
    -e "s|NODE_USER|$NODE_USER|g" \
    -e "s|MITHRIL_SERVICE|$MITHRIL_SERVICE|g" \
    -e "s|MITHRIL_HOME|$MITHRIL_HOME|g"
sudo cp -p services/$MITHRIL_SERVICE.temp $SERVICE_PATH/$MITHRIL_SERVICE
rm services/$MITHRIL_SERVICE.temp

# Reload system daemon.
sudo systemctl daemon-reload
sudo systemctl start $MITHRIL_SERVICE
sudo systemctl enable $MITHRIL_SERVICE

