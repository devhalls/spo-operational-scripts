#!/bin/bash
# Usage: node/download.sh [
#   download |
#   arm |
#   node |
#   path |
#   help [?-h]
# ]
#
# Info:
#
#   - download) Installs a Cardano node and all dependencies. Default value if no options are passed.
#   - arm) Download node binaries from the arm repositories.
#   - node) Download node binaries from the cardano repositories.
#   - path) Set $BIN_PATH permissions and check if its in the $PATH.
#   - help) View this files help.

source "$(dirname "$0")/../../env"
source "$(dirname "$0")/../common.sh"

download_arm() {
  print 'DOWNLOAD' "Downloading node arm binaries"
  local filename="cardano-${NODE_VERSION//./_}-aarch64-static-musl-ghc_966"
  mkdir -p downloads
  wget -O downloads/$filename $NODE_REMOTE_ARM/$filename.tar.zst
  if [ $? -eq 0 ]; then
    tar --zstd -xvf downloads/$filename -C downloads
    cp -a downloads/$filename/. $BIN_PATH/
    rm -R downloads
  else
    rm -R downloads
    print 'ERROR' "Unable to download arm binaries" $red
    exit 1
  fi
  print 'DOWNLOAD' "Node binaries moved to $BIN_PATH" $green
  return 0
}

download_node() {
  print 'DOWNLOAD' "Downloading node binaries"
  mkdir -p downloads
  case $(platform) in
    windows) p="win64" ;;
    *) p=$(platform) ;;
  esac
  local filename="cardano-node-$NODE_VERSION-$p.tar.gz"
  wget -O downloads/$filename $NODE_REMOTE/$filename
  if [ $? -eq 0 ]; then
    tar -xvzf downloads/$filename -C downloads
    cp -a downloads/bin/. $BIN_PATH/
    rm -R downloads
  else
    rm -R downloads
    print 'ERROR' "Unable to download binaries" $red
    exit 1
  fi
  print 'DOWNLOAD' "Node binaries moved to $BIN_PATH" $green
  return 0
}

download_set_path() {
  print 'DOWNLOAD' "Creating bin path and setting download permissions"
  chmod +x -R $BIN_PATH
  if [[ "$PATH" != *"$HOME/local/bin/"* ]]; then
    sed -i '$ a\export PATH="$PATH:$HOME/local/bin/"' ~/.bashrc
  fi
  source ~/.bashrc
  print 'DOWNLOAD' "Bin path and permissions set" $green
}

download() {
  p=$(platform_arm)
  case $p in
      arm) download_arm ;;
      *) download_node ;;
  esac
  download_set_path
}

case $1 in
  download) download ;;
  arm) download_arm ;;
  node) download_node ;;
  path) download_set_path ;;
  help) help "${2:-"--help"}" ;;
  *) download ;;
esac
