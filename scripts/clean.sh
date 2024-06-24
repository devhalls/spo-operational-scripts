#!/bin/bash

source "$(dirname "$0")/../networks/${1}/env"
source "$(dirname "$0")/common/common.sh"
help 2 1 ${@} || exit

sudo systemctl stop "${NETWORK_SERVICE}"
sudo rm /etc/systemd/system/$NETWORK_SERVICE
sudo rm -R networks/$NODE_NETWORK

sudo systemctl daemon-reload

