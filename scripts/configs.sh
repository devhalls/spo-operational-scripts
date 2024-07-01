#!/bin/bash

source "$(dirname "$0")/../env"
source "$(dirname "$0")/common/common.sh"
help 3 0 ${@} || exit

# Copy the env and download config files.
cp -p env $NETWORK_PATH/env
 for C in ${CONFIG_DOWNLOADS[@]}; do
    wget -O $NETWORK_PATH/$C $CONFIG_REMOTE/$C
done
print 'INSTALL' "Downloaded configs for $NODE_NETWORK"
