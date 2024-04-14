#!/bin/bash

source "env"
BIN_PATH=$HOME/.local/bin
SERVICE_NAME=cardano-node-$NODE_NETWORK.service
SERVICE_PATH=/etc/systemd/system/$SERVICE_NAME
NODE_DOWNLOAD=cardano-node-$NODE_VERSION-linux.tar.gz 
NODE_REMOTE=https://github.com/IntersectMBO/cardano-node/releases/download/$NODE_VERSION/$NODE_DOWNLOAD
CONFIG_REMOTE=https://book.play.dev.cardano.org/environments/$NODE_NETWORK
CONFIG_DOWNLOADS=(
    "conway-genesis.json" 
    "alonzo-genesis.json" 
    "shelley-genesis.json" 
    "byron-genesis.json" 
    "topology.json" 
    "submit-api-config.json" 
    "db-sync-config.json" 
    "config.json"
)
GUILD_REMOTE=https://raw.githubusercontent.com/cardano-community/guild-operators/master/scripts/cnode-helper-scripts
GUILD_SCRIPT_DOWNLOADS=(
    "gLiveView.sh"
    "env"
)

# Install dependencies.
sudo apt install jq bc tcptraceroute supervisor -y

# Create directories.
mkdir -p downloads temp $NETWORK_PATH $NETWORK_PATH/keys $NETWORK_PATH/scripts

# Download and extract cardano node packages.
wget -O $NODE_DOWNLOAD $NODE_REMOTE 
tar -xvzf $NODE_DOWNLOAD -C downloads

# Copy node and cli to local bin.
cp -p downloads/cardano-node $BIN_PATH/cardano-node
cp -p downloads/cardano-cli $BIN_PATH/cardano-cli
rm -R downloads $NODE_DOWNLOAD

# Download config files and copy env file.
if [ ! -f "$NETWORK_PATH/env" ]; then
    cp -p env $NETWORK_PATH/env
    for C in ${CONFIG_DOWNLOADS[@]}; do
        wget -O $NETWORK_PATH/$C $CONFIG_REMOTE/$C
    done
    echo "[DONE] Downloaded configs for $NODE_NETWORK"
else
    echo "[SKIP] Downloading configs for $NODE_NETWORK"
fi

# Download guild helper scripts (gLiveView).
for G in ${GUILD_SCRIPT_DOWNLOADS[@]}; do
    wget -O $NETWORK_PATH/scripts/$G $GUILD_REMOTE/$G
done
chmod 755 $NETWORK_PATH/scripts/gLiveView.sh
sed -i $NETWORK_PATH/scripts/env \
    -e "s|\#CONFIG=\"\${CNODE_HOME}\/files\/config.json\"|CONFIG=\"${NETWORK_PATH}\/config.json\"|g" \
    -e "s|\#SOCKET=\"\${CNODE_HOME}\/sockets\/node.socket\"|SOCKET=\"${NETWORK_PATH}\/db\/socket\"|g"
    
# Format supervisor service files.
sudo cp -p services/cardano-node.service $SERVICE_PATH
sudo chmod 644 $SERVICE_PATH
sudo sed -i $SERVICE_PATH \
    -e "s|NODE_NETWORK|$NODE_NETWORK|g" \
    -e "s|NODE_HOME|$NODE_HOME|g" \
    -e "s|NODE_USER|$NODE_USER|g" \
    -e "s|SERVICE_NAME|$SERVICE_NAME|g"

# Start the service
sudo systemctl daemon-reload
sudo systemctl enable $SERVICE_NAME
sudo systemctl start $SERVICE_NAME

# Complete and sidplay versions.
cardano-node --version
cardano-cli --version
echo "[DONE] Node installed and started as $NODE_TYPE"
