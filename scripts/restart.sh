#!/bin/bash

bash scripts/help.sh 2 1 ${@} || exit
source "$(dirname "$0")/../networks/${2}/env"

systemctl restart "${NETWORK_SERVICE}"
echo "[RESTART] Node service ${NODE_NETWORK} restarted"
