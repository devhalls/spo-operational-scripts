#!/bin/bash

bash scripts/help.sh 6 1 ${@} || exit
source "$(dirname "$0")/../networks/${1}/env"

journalctl -u $NETWORK_SERVICE -f -o cat
