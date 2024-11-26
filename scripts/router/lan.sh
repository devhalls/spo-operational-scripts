#!/bin/bash

source "$(dirname "$0")/../../env"
source "$(dirname "$0")/common.sh"

cd /etc/netplan
sudo nano 50-cloud-init.yaml

#network:
#    ethernets:
#        enp86s0:
#            dhcp4: true
#    version: 2
#    wifis:
#        wlo1:
#            access-points:
#                XXXXXXX:
#                    password: XXXXXXX
#            dhcp4: false
#            addresses:
#                - 192.168.1.xxx/24
#            routes:
#                - to: default
#                  via: 192.168.1.xxx
#            nameservers:
#                addresses:
#                  - 8.8.8.8
#                  - 8.8.4.4

sudo netplan try
