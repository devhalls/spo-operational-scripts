#!/bin/bash

source "$(dirname "$0")/../../env"
source "$(dirname "$0")/../common.sh"
help 20 0 ${@} || exit 1

# Install or update rust toolchain & dependencies
if ! command -v rustup 2>&1 >/dev/null
then
  print 'MITHRIL BUILD' "installing rust, follow the on screen instructions"
  sudo $PACKAGER install build-essential m4 libssl-dev jq
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
else
  print 'MITHRIL BUILD' "updating rust"
  rustup update
fi

# Check the versions
config=`wget -q -O - https://raw.githubusercontent.com/input-output-hk/mithril/main/networks.json`
min=$(jq -r ".\"$NODE_NETWORK\".\"cardano-minimum-version\".\"mithril-signer\"" <<< "$config")
current=`cardano-node --version`

print 'MITHRIL BUILD' "cardano-node min version: $min"
print 'MITHRIL BUILD' "cardano-node current version: $current"
print 'MITHRIL BUILD' "mithril version: $MITHRIL_VERSION"

# Download and build the signer
cd ~/src
sudo rm -R mithril
git clone https://github.com/input-output-hk/mithril.git
cd mithril
git checkout $MITHRIL_VERSION
cd mithril-signer
make test
make build

# Move the compiled signer to the bin
sudo mv -f mithril-signer $BIN_PATH
version=`$MITHRIL_SIGNER -V`
print 'MITHRIL BUILD' "mithril-signer version: $version" $green
