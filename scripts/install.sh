#!/bin/bash

source "$(dirname "$0")/../env"
source "$(dirname "$0")/common/common.sh"
help 3 0 ${@} || exit 1

# Check the env has been created
if [ ! -f "$(dirname "$0")/../env" ]; then
  print 'INSTALL ERROR' 'No env file found, please review README.md' $red
  exit 1
fi

# Install dependencies.
print 'INSTALL' 'Install dependencies'
sudo $PACKAGER install jq bc tcptraceroute supervisor wget -y

# Create directories.
print 'INSTALL' 'Create directories'
mkdir -p temp $NETWORK_PATH $NETWORK_PATH/keys $NETWORK_PATH/scripts $BIN_PATH

# Download and extract cardano node packages.
if [[ $NODE_BUILD < 1 ]]; then
  print 'INSTALL' 'Downloading node binaries'
  mkdir -p downloads
  wget -O downloads/$NODE_DOWNLOAD $NODE_REMOTE
  tar -xvzf downloads/$NODE_DOWNLOAD -C downloads
  rm downloads/$NODE_DOWNLOAD
  cp -a downloads/. $BIN_PATH/
  rm -R downloads

# Or run the build script.
else
  print 'INSTALL' 'Building node binaries'
  bash scripts/build.sh
fi

# Copy the env and download config files.
cp -p env $NETWORK_PATH/env
 for C in ${CONFIG_DOWNLOADS[@]}; do
    wget -O $NETWORK_PATH/$C $CONFIG_REMOTE/$C
done
print 'INSTALL' "Downloaded configs for $NODE_NETWORK"

# Download guild helper scripts (gLiveView).
for G in ${GUILD_SCRIPT_DOWNLOADS[@]}; do
    wget -O $NETWORK_PATH/scripts/$G $GUILD_REMOTE/$G
done
chmod +x $NETWORK_PATH/scripts/gLiveView.sh
sed -i $NETWORK_PATH/scripts/env \
    -e "s|\#CONFIG=\"\${CNODE_HOME}\/files\/config.json\"|CONFIG=\"${NETWORK_PATH}\/config.json\"|g" \
    -e "s|\#SOCKET=\"\${CNODE_HOME}\/sockets\/node.socket\"|SOCKET=\"${NETWORK_PATH}\/db\/socket\"|g" \
    -e "s|\#CNODE_PORT=6000|CNODE_PORT=\"${NODE_PORT}\"|g" \
    -e "s|\#CNODEBIN=\"\${HOME}\/.local\/bin\/cardano-node\"|CNODEBIN=\"\${HOME}\/local\/bin\/cardano-node\"|g" \
    -e "s|\#CCLI=\"\${HOME}\/.local\/bin\/cardano-cli\"|CCLI=\"\${HOME}\/local\/bin\/cardano-cli\"|g" \
makdir $NETWORK_PATH/logs

# Format supervisor service files.
cp -p services/cardano-node.service services/$NETWORK_SERVICE.temp
sed -i services/$NETWORK_SERVICE.temp \
    -e "s|NODE_NETWORK|$NODE_NETWORK|g" \
    -e "s|NODE_HOME|$NODE_HOME|g" \
    -e "s|NODE_USER|$NODE_USER|g" \
    -e "s|NETWORK_SERVICE|$NETWORK_SERVICE|g"
sudo cp -p services/$NETWORK_SERVICE.temp $SERVICE_PATH/$NETWORK_SERVICE
rm services/$NETWORK_SERVICE.temp

# Enable the service
sudo systemctl daemon-reload
sudo systemctl enable $NETWORK_SERVICE

# Complete and display versions.
print 'INSTALL' "Node installed as $NODE_TYPE"
$CNNODE --version
$CNCLI --version
print 'INSTALL COMPLETE' "Edit your topology config at $NETWORK_PATH/typology.json" $green
print 'INSTALL COMPLETE' "Then start the node service: sudo systemctl start $NETWORK_SERVICE" $green
