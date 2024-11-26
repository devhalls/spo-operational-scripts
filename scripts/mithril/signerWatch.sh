#!/bin/bash

source "$(dirname "$0")/../../env"
source "$(dirname "$0")/../common.sh"
help 23 1 ${@} || exit

journalctl -u $MITHRIL_SERVICE -f -o cat
