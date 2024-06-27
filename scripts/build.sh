#!/bin/bash

source "$(dirname "$0")/common/common.sh"
help 1 0 ${@} || exit
source "$(dirname "$0")/../env"

# Install dependencies.
print 'BUILD' 'Install dependencies'

cd ~
sudo $PACKAGER update -y
sudo $PACKAGER install autoconf \
               automake \
               build-essential \
               curl \
               g++ \
               git \
               jq \
               libffi-dev \
               libffi8 \
               libffi8ubuntu1 \
               libgmp-dev \
               libgmp10 \
               liblmdb-dev \
               libncurses-dev \
               libsodium-dev \
               libssl-dev \
               libsystemd-dev \
               libtool \
               make \
               pkg-config \
               tmux \
               wget \
               zlib1g-dev -y

# Installing the Haskell environment.
print 'BUILD' 'Installing Haskell with options P N N:'
curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | sh

# Exit if the Haskell installation failed to generate the ghcup env
if [ ! -f "$NODE_HOME/../.ghcup/env" ]; then
    print 'BUILD ERROR' "Could not configure ghcup env, retry installation" $red
    exit 1
fi

source ~/.bashrc
source $NODE_HOME/../.ghcup/env

# Set versions
print 'BUILD' 'Set versions'
ghcup install ghc $GHC_VERSION
ghcup install cabal $CABAL_VERSION
ghcup set ghc $GHC_VERSION
ghcup set cabal $CABAL_VERSION
IOHKNIX_VERSION="$(curl https://raw.githubusercontent.com/IntersectMBO/cardano-node/$NODE_VERSION/flake.lock | jq -r '.nodes.iohkNix.locked.rev')"
SODIUM_VERSION="$(curl https://raw.githubusercontent.com/input-output-hk/iohk-nix/$IOHKNIX_VERSION/flake.lock | jq -r '.nodes.sodium.original.rev')"
SECP256K1_VERSION="$(curl https://raw.githubusercontent.com/input-output-hk/iohk-nix/$IOHKNIX_VERSION/flake.lock | jq -r '.nodes.secp256k1.original.ref')"
BLST_VERSION="$(curl https://raw.githubusercontent.com/input-output-hk/iohk-nix/master/flake.lock | jq -r '.nodes.blst.original.ref')"
echo -e "$orange[BUILD] NODE_VERSION: $NODE_VERSION$nc"
echo -e "$orange[BUILD] SODIUM_VERSION: $SODIUM_VERSION$nc"
echo -e "$orange[BUILD] IOHKNIX_VERSION: $IOHKNIX_VERSION$nc"
echo -e "$orange[BUILD] SECP256K1_VERSION: $SECP256K1_VERSION$nc"
echo -e "$orange[BUILD] BLST_VERSION: $BLST_VERSION$nc"

# Confirm continue build?
confirm

# Create directories.
print 'BUILD' 'Create directories'
mkdir -p ~/src

# Install sodium.
print 'BUILD' "Installing sodium"
cd ~/src
sudo rm -R libsodium
: ${SODIUM_VERSION:='dbb48cc'}
print 'BUILD' "Version: $SODIUM_VERSION"

git clone https://github.com/intersectmbo/libsodium
cd libsodium
git checkout $SODIUM_VERSION
./autogen.sh
./configure
make
make check
sudo make install
sed -i '$ a\export LD_LIBRARY_PATH="/usr/local/lib:$LD_LIBRARY_PATH"' ~/.bashrc
sed -i '$ a\export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH"' ~/.bashrc
source ~/.bashrc

# Install secp256k1.
print 'BUILD' 'Installing secp256k1'
cd ~/src
sudo rm -R secp256k1
: ${SECP256K1_VERSION:='v0.3.2'}
print 'BUILD' "Version: $SECP256K1_VERSION"

git clone --depth 1 --branch ${SECP256K1_VERSION} https://github.com/bitcoin-core/secp256k1
cd secp256k1
./autogen.sh
./configure --enable-module-schnorrsig --enable-experimental
make
make check
sudo make install
sudo ldconfig

# Install blst.
print 'BUILD' 'Installing blst'
cd ~/src
sudo rm -R blst
: ${BLST_VERSION:='v0.3.11'}
print 'BUILD' "Version: $BLST_VERSION"

git clone --depth 1 --branch ${BLST_VERSION} https://github.com/supranational/blst
cd blst
./build.sh
cat > libblst.pc << EOF
prefix=/usr/local
exec_prefix=\${prefix}
libdir=\${exec_prefix}/lib
includedir=\${prefix}/include

Name: libblst
Description: Multilingual BLS12-381 signature library
URL: https://github.com/supranational/blst
Version: ${BLST_VERSION#v}
Cflags: -I\${includedir}
Libs: -L\${libdir} -lblst
EOF
sudo cp libblst.pc /usr/local/lib/pkgconfig/
sudo cp bindings/blst_aux.h bindings/blst.h bindings/blst.hpp  /usr/local/include/
sudo cp libblst.a /usr/local/lib
sudo chmod u=rw,go=r /usr/local/{lib/{libblst.a,pkgconfig/libblst.pc},include/{blst.{h,hpp},blst_aux.h}}

# Installing the target node version.
print 'BUILD' "Installing cardano node $NODE_VERSION"
cd ~/src
sudo rm -R cardano-node
git clone https://github.com/intersectmbo/cardano-node.git
cd cardano-node
git fetch --all --recurse-submodules --tags
git checkout tags/$NODE_VERSION

# Configuring and build.
echo "with-compiler: ghc-$GHC_VERSION" >> cabal.project.local
source ~/.bashrc
cabal update
cabal build all
cabal build cardano-cli

# Copy files to the bin and add to $PATH.
cp -p "$(./scripts/bin-path.sh cardano-node)" ~/local/bin/
cp -p "$(./scripts/bin-path.sh cardano-cli)" ~/local/bin/
sed -i '$ a\export PATH="$PATH:$HOME/local/bin/"' ~/.bashrc
source ~/.bashrc

# Test versions.
cardano-cli --version
cardano-node --version
print 'BUILD COMPLETE' 'Complete building cardano-cli cardano-node' $green
