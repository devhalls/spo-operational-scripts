#!/bin/bash

bash scripts/help.sh 4 1 ${@} || exit
source "$(dirname "$0")/../networks/${1}/env"

sudo systemctl restart "${NETWORK_SERVICE}"
echo "[RESTART] Node service ${NETWORK_SERVICE} restarted"
