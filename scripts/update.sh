#!/bin/bash

source "$(dirname "$0")/../networks/${1}/env"
source "$(dirname "$0")/common/common.sh"
# help 1 0 ${@} || exit

nodeVersion=${2}

print 'UPDATE' 'Updating env NODE_VERSION'
sed -i $NETWORK_PATH/env \
      -e "s|\NODE_VERSION=\"\${NODE_VERSION}\"|NODE_VERSION=\"${nodeVersion}\"|g"

cp $NETWORK_PATH/env env

print 'UPDATE' 'Building node binaries'
bash scripts/build.sh || exit 1
