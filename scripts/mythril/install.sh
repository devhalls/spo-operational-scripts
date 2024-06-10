#!/bin/bash

# Info : Install dependencies.
# Use  : cd $NODE_HOME
#      : mythril/install.sh

RELAY_IP=81.1.1.1
RELAY_PORT=5001

rustup update

# Download, install and verify the signer
cd git
git clone https://github.com/input-output-hk/mithril.git
cd mithril
git checkout 2403.1
cd mithril-signer
make build
./mithril-signer -V

# Move the compiled signer to the bin
sudo mv -f mithril-signer /usr/.local/bin

# Configure env and run signer as systemd service
cd $NODE_HOME
nano mithril.env
chmod 750 ./mithril-signer.sh
./mithril-signer.sh -d

# Configure the firewall to allow for the mythril relay.
sudo ufw status
sudo ufw allow proto tcp from $RELAY_IP to any port $RELAY_PORT
sudo ufw reload
sudo ufw status

# Check the status, which should fail at this stage
sudo systemctl start cnode-mithril-signer.service
sudo systemctl status cnode-mithril-signer.service
