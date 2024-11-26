#!/bin/bash

source "$(dirname "$0")/../../env"
source "$(dirname "$0")/../common.sh"
help 25 1 ${@} || exit

sudo systemctl daemon-reload
sudo systemctl start $MITHRIL_SERVICE
sudo systemctl enable $MITHRIL_SERVICE
print 'STARTED' "Mithril service ${MITHRIL_SERVICE} restarted" $green
