#!/bin/bash

source "$(dirname "$0")/../networks/${1}/env"
source "$(dirname "$0")/common/common.sh"
help 6 1 ${@} || exit

journalctl -u $NETWORK_SERVICE -f -o cat
