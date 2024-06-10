#!/bin/bash

bash scripts/help.sh 2 1 ${@} || exit
source "$(dirname "$0")/../networks/${1}/env"

sudo systemctl stop "${NETWORK_SERVICE}"
sudo rm /etc/systemd/system/$NETWORK_SERVICE
sudo rm -R networks/$NODE_NETWORK

sudo systemctl daemon-reload

