#!/bin/bash
# Usage: node/build.sh (
#   build |
#   dependencies |
#   sodium |
#   secp |
#   blst |
#   node |
#   help [-h <BOOLEAN>]
# )
#
# Info:
#
#   - build) Build the full node from source. Default value if no option is passed.
#   - dependencies) Download and install compiler dependencies.
#   - sodium) Build libsodium from source.
#   - secp) Build secp256k1 from source.
#   - blst) Build libblst from source.
#   - node) Build cardano node and cli from source.
#   - help) View this files help.

source "$(dirname "$0")/../common.sh"

build_dependencies() {
    print 'BUILD' 'Install dependencies'
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

    print 'BUILD' 'Installing Haskell'
    curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | sh
    if [ ! -f "$NODE_HOME/../.ghcup/env" ]; then
        print 'BUILD ERROR' "Could not configure ghcup env, retry installation" $red
        exit 1
    fi
    source ~/.bashrc
    source $NODE_HOME/../.ghcup/env

    print 'BUILD' 'Set node build versions'
    ghcup install ghc $GHC_VERSION
    ghcup install cabal $CABAL_VERSION
    ghcup set ghc $GHC_VERSION
    ghcup set cabal $CABAL_VERSION
    IOHKNIX_VERSION="$(curl https://raw.githubusercontent.com/IntersectMBO/cardano-node/$NODE_VERSION/flake.lock | jq -r '.nodes.iohkNix.locked.rev')"
    SODIUM_VERSION="$(curl https://raw.githubusercontent.com/input-output-hk/iohk-nix/$IOHKNIX_VERSION/flake.lock | jq -r '.nodes.sodium.original.rev')"
    SECP256K1_VERSION="$(curl https://raw.githubusercontent.com/input-output-hk/iohk-nix/$IOHKNIX_VERSION/flake.lock | jq -r '.nodes.secp256k1.original.ref')"
    BLST_VERSION="$(curl https://raw.githubusercontent.com/input-output-hk/iohk-nix/master/flake.lock | jq -r '.nodes.blst.original.ref')"
    print 'BUILD' "NODE_VERSION: $NODE_VERSION"
    print 'BUILD' "SODIUM_VERSION: $SODIUM_VERSION"
    print 'BUILD' "IOHKNIX_VERSION: $IOHKNIX_VERSION"
    print 'BUILD' "SECP256K1_VERSION: $SECP256K1_VERSION"
    print 'BUILD' "BLST_VERSION: $BLST_VERSION"
    confirm 'Please confirm versions to continue (y|n)'
    print 'BUILD' 'Create directories'
    mkdir -p ~/src
    return 0
}

build_sodium() {
    print 'BUILD' "Installing sodium"
    IOHKNIX_VERSION="$(curl https://raw.githubusercontent.com/IntersectMBO/cardano-node/$NODE_VERSION/flake.lock | jq -r '.nodes.iohkNix.locked.rev')"
    SODIUM_VERSION="$(curl https://raw.githubusercontent.com/input-output-hk/iohk-nix/$IOHKNIX_VERSION/flake.lock | jq -r '.nodes.sodium.original.rev')"
    cd ~/src
    sudo rm -R libsodium
    : ${SODIUM_VERSION:='dbb48cc'}
    git clone https://github.com/intersectmbo/libsodium
    cd libsodium
    git checkout $SODIUM_VERSION
    ./autogen.sh
    ./configure
    make
    make check
    sudo make install
    if [[ ! $LD_LIBRARY_PATH ]]; then
        print 'BUILD' "Set LD_LIBRARY_PATH and PKG_CONFIG_PATH"
        source ~/.bashrc
        sed -i '$ a\export LD_LIBRARY_PATH="/usr/local/lib:$LD_LIBRARY_PATH"' ~/.bashrc
        sed -i '$ a\export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH"' ~/.bashrc
        source ~/.bashrc
    fi
    return 0
}

build_secp() {
    print 'BUILD' 'Installing secp256k1'
    IOHKNIX_VERSION="$(curl https://raw.githubusercontent.com/IntersectMBO/cardano-node/$NODE_VERSION/flake.lock | jq -r '.nodes.iohkNix.locked.rev')"
    SECP256K1_VERSION="$(curl https://raw.githubusercontent.com/input-output-hk/iohk-nix/$IOHKNIX_VERSION/flake.lock | jq -r '.nodes.secp256k1.original.ref')"
    cd ~/src
    sudo rm -R secp256k1
    : ${SECP256K1_VERSION:='v0.3.2'}
    git clone --depth 1 --branch ${SECP256K1_VERSION} https://github.com/bitcoin-core/secp256k1
    cd secp256k1
    ./autogen.sh
    ./configure --enable-module-schnorrsig --enable-experimental
    make
    make check
    sudo make install
    sudo ldconfig
    return 0
}

build_blst() {
    print 'BUILD' 'Installing blst'
    cd ~/src
    sudo rm -R blst
    : ${BLST_VERSION:='v0.3.11'}
    print 'BUILD' "Version: $BLST_VERSION"
    git clone --depth 1 --branch ${BLST_VERSION} https://github.com/supranational/blst
    cd blst
    ./build.sh
    cat >libblst.pc <<EOF
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
    sudo cp bindings/blst_aux.h bindings/blst.h bindings/blst.hpp /usr/local/include/
    sudo cp libblst.a /usr/local/lib
    sudo chmod u=rw,go=r /usr/local/{lib/{libblst.a,pkgconfig/libblst.pc},include/{blst.{h,hpp},blst_aux.h}}
    return 0
}

build_node() {
    print 'BUILD' "Installing cardano node $NODE_VERSION"
    cd ~/src
    sudo rm -R cardano-node
    git clone https://github.com/intersectmbo/cardano-node.git
    cd cardano-node
    git fetch --all --recurse-submodules --tags
    git checkout tags/$NODE_VERSION
    echo "with-compiler: ghc-$GHC_VERSION" >>cabal.project.local
    source ~/.bashrc
    cabal update
    cabal build all
    cabal build cardano-cli

    print 'BUILD' 'Copy files to the bin and add to $PATH'
    cp -p "$(./scripts/bin-path.sh cardano-node)" ~/local/bin/
    cp -p "$(./scripts/bin-path.sh cardano-cli)" ~/local/bin/
    if [[ "$PATH" != *"$HOME/local/bin/"* ]]; then
        sed -i '$ a\export PATH="$PATH:$HOME/local/bin/"' ~/.bashrc
    fi
    source ~/.bashrc
    return 0
}

build() {
    build_dependencies
    build_sodium
    build_secp
    build_blst
    build_node
    $CNNODE --version
    $CNCLI --version
    print 'BUILD' 'Complete building cardano-cli cardano-node' $green
    return 0
}

case $1 in
    build) build ;;
    dependencies) build_dependencies ;;
    sodium) build_sodium ;;
    secp) build_secp ;;
    blst) build_blst ;;
    node) build_node ;;
    help) help "${2:-"--help"}" ;;
    *) build ;;
esac
