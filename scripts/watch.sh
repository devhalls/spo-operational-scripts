#!/bin/bash

bash scripts/help.sh 4 1 ${@} || exit
source "$(dirname "$0")/../networks/${2}/env"

journalctl -u $NETWORK_SERVICE.service -f -o cat
