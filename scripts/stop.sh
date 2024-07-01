#!/bin/bash

source "$(dirname "$0")/../networks/${1}/env"
source "$(dirname "$0")/common/common.sh"
help 15 1 ${@} || exit

sudo systemctl stop "${NETWORK_SERVICE}"
print 'STOP' "Node service ${NETWORK_SERVICE} stopped"
