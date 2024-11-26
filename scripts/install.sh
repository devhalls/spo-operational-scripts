#!/bin/bash
# Usage: scripts/install.sh
#
# Info:
#
#   - Cardano node installation script.
#   - Checks the env file has been created.
#   - Installs OS package dependencies.
#   - Created node directories.
#   - Build cardano packages based on $NODE_BUILD option.
#   - Download config files and gLiveView monitor.
#   - Format supervisor files and prepare services.

source "$(dirname "$0")/../env"
source "$(dirname "$0")/common.sh"

if [ ! -f "$(dirname "$0")/../env" ]; then
  print 'INSTALL ERROR' 'No env file found, please review README.md' $red
  exit 1
fi

print 'INSTALL' 'Installing dependencies'
sudo $PACKAGER install jq bc tcptraceroute supervisor wget -y

print 'INSTALL' 'Create node directories'
mkdir -p $NETWORK_PATH $NETWORK_PATH/temp $NETWORK_PATH/keys $NETWORK_PATH/scripts $NETWORK_PATH/logs $BIN_PATH

if [[ $NODE_BUILD == 1 ]]; then
  bash scripts/install/download.sh || exit 1
elif [[ $NODE_BUILD == 2 ]]; then
  bash scripts/install/build.sh || exit 1
fi

bash scripts/install/configs.sh || exit 1

bash scripts/install/guild.sh || exit 1

cp -p services/cardano-node.service services/$NETWORK_SERVICE.temp
sed -i services/$NETWORK_SERVICE.temp \
    -e "s|NODE_NETWORK|$NODE_NETWORK|g" \
    -e "s|NODE_HOME|$NODE_HOME|g" \
    -e "s|NODE_USER|$NODE_USER|g" \
    -e "s|NETWORK_SERVICE|$NETWORK_SERVICE|g"
sudo cp -p services/$NETWORK_SERVICE.temp $SERVICE_PATH/$NETWORK_SERVICE
rm services/$NETWORK_SERVICE.temp

sudo systemctl daemon-reload
sudo systemctl enable $NETWORK_SERVICE

$CNNODE --version
$CNCLI --version
print 'INSTALL' "Node installed" $green
print 'INSTALL COMPLETE' "Edit your topology config at $NETWORK_PATH/topology.json" $green
print 'INSTALL COMPLETE' "Then start the node service: sudo systemctl start $NETWORK_SERVICE" $green
