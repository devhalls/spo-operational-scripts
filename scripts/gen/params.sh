#!/bin/bash

source "$(dirname "$0")/../common/common.sh"
help 10 1 ${@} || exit
source "$(dirname "$0")/../../networks/${1}/env"

cardano-cli query protocol-parameters \
    $NETWORK_ARG \
    --socket-path $NETWORK_SOCKET_PATH \
    --out-file $NETWORK_PATH/${2:-"params.json"}

