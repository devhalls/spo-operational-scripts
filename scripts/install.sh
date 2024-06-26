#!/bin/bash

bash scripts/help.sh 3 0 ${@} || exit
source "$(dirname "$0")/../env"

# Install dependencies.
sudo $PACKAGER install jq bc tcptraceroute supervisor wget -y

# Create directories.
mkdir -p temp $NETWORK_PATH $NETWORK_PATH/keys $NETWORK_PATH/scripts $BIN_PATH

# Download and extract cardano node packages.
if [[ $NODE_BUILD < 1 ]]; then
  echo "[INSTALL] Downloading node binaries"
  mkdir -p downloads
  wget -O downloads/$NODE_DOWNLOAD $NODE_REMOTE
  tar -xvzf downloads/$NODE_DOWNLOAD -C downloads
  rm downloads/$NODE_DOWNLOAD
  cp -a downloads/. $BIN_PATH/
  rm -R downloads

# Or run the build script.
else
  echo "[INSTALL] Building node binaries"
  # bash scripts/build.sh
fi

# Download config files and copy env file.
if [ ! -f "$NETWORK_PATH/env" ]; then
    cp -p env $NETWORK_PATH/env
    for C in ${CONFIG_DOWNLOADS[@]}; do
        wget -O $NETWORK_PATH/$C $CONFIG_REMOTE/$C
    done
    echo "[INSTALL] Downloaded configs for $NODE_NETWORK"
else
    echo "[INSTALL] Skipped downloading configs for $NODE_NETWORK"
fi

# Download guild helper scripts (gLiveView).
for G in ${GUILD_SCRIPT_DOWNLOADS[@]}; do
    wget -O $NETWORK_PATH/scripts/$G $GUILD_REMOTE/$G
done
chmod +x $NETWORK_PATH/scripts/gLiveView.sh
sed -i $NETWORK_PATH/scripts/env \
    -e "s|\#CONFIG=\"\${CNODE_HOME}\/files\/config.json\"|CONFIG=\"${NETWORK_PATH}\/config.json\"|g" \
    -e "s|\#SOCKET=\"\${CNODE_HOME}\/sockets\/node.socket\"|SOCKET=\"${NETWORK_PATH}\/db\/socket\"|g"

# Format supervisor service files.
cp -p services/cardano-node.service services/$NETWORK_SERVICE.temp
sed -i services/$NETWORK_SERVICE.temp \
    -e "s|NODE_NETWORK|$NODE_NETWORK|g" \
    -e "s|NODE_HOME|$NODE_HOME|g" \
    -e "s|NODE_USER|$NODE_USER|g" \
    -e "s|NETWORK_SERVICE|$NETWORK_SERVICE|g"
sudo cp -p services/$NETWORK_SERVICE.temp $SERVICE_PATH/$NETWORK_SERVICE
rm services/$NETWORK_SERVICE.temp

# Start the service
sudo systemctl daemon-reload
sudo systemctl enable $NETWORK_SERVICE
sudo systemctl start $NETWORK_SERVICE

# Complete and display versions.
$CNNODE --version
$CNCLI --version
echo "[INSTALL] Node installed and started as $NODE_TYPE"
