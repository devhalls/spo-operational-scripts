#!/bin/bash

source "$(dirname "$0")/../networks/${1}/env"
source "$(dirname "$0")/common/common.sh"
help 4 1 ${@} || exit

sudo systemctl restart "${NETWORK_SERVICE}"
echo "[RESTART] Node service ${NETWORK_SERVICE} restarted"
