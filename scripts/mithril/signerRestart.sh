#!/bin/bash

source "$(dirname "$0")/../../env"
source "$(dirname "$0")/../common.sh"
help 22 1 ${@} || exit

sudo systemctl restart "${MITHRIL_SERVICE}"
print 'RESTART' "Mithril service ${MITHRIL_SERVICE} restarted"
