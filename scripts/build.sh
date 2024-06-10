#!/bin/bash

bash scripts/help.sh 1 0 ${@} || exit
source "$(dirname "$0")/../env"
orange='\033[0;33m'
nc='\033[0m'

confirm() {
  message=${1:-'Do you want to continue?'}
  echo -e "$orange$message (type 'yes' to continue)$nc"
  read input
  if [ "$input" != "yes" ]
  then
    exit 1
  else
    echo -e "$orange...$nc"
  fi
}

# Install dependencies.
cd ~
sudo $PACKAGER update -y
sudo $PACKAGER autoconf \
               automake \
               build-essential \
               curl \
               g++ \
               git \
               install \
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
echo -e "$orange[BUILD] Installing the Haskell environment, press enter to apply all defaults:$nc"
curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | sh
source ~/.bashrc

# Set versions
echo -e "$orange[BUILD] Set versions$nc"
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

confirm

# Create directories.
echo -e "$orange[BUILD] Create directories$nc"
mkdir -p ~/src

# Install sodium.
cd ~/src
sudo rm -R libsodium
: ${SODIUM_VERSION:='dbb48cc'}
echo -e "$orange[BUILD] Installing sodium $SODIUM_VERSION $nc"
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
cd ~/src
sudo rm -R secp256k1
: ${SECP256K1_VERSION:='v0.3.2'}
echo -e "$orange[BUILD] Installing secp256k1 $SECP256K1_VERSION $nc"
git clone --depth 1 --branch ${SECP256K1_VERSION} https://github.com/bitcoin-core/secp256k1
cd secp256k1
./autogen.sh
./configure --enable-module-schnorrsig --enable-experimental
make
make check
sudo make install
sudo ldconfig

# Install blst.
cd ~/src
sudo rm -R blst
: ${BLST_VERSION:='v0.3.11'}
echo -e "$orange[BUILD] Installing blst $BLST_VERSION $nc"
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
echo -e "$orange[BUILD] Installing cardano node $NODE_VERSION $nc"
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
echo -e "$orange[BUILD] Complete building cardano-cli cardano-node$nc"
