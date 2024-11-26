#!/bin/bash
# Usage: scripts/query/params.sh <field>
#
# Info:
#
#   - Generates network params file named 'params.json'
#   - Echos the passed field value if set or all values if not

source "$(dirname "$0")/../../env"
source "$(dirname "$0")/../common.sh"
field="${1}"

$CNCLI conway query protocol-parameters \
    $NETWORK_ARG \
    --socket-path $NETWORK_SOCKET_PATH \
    --out-file $NETWORK_PATH/params.json

if [ "$field" ]; then
    fieldValue=$(cat $NETWORK_PATH/params.json | jq -r ".$field")
    print "$field" "$fieldValue" $green
else
    print "PARAMS" "$(cat $NETWORK_PATH/params.json)" $green
    print "PARAMS" "saved to $NETWORK_PATH/params.json" $green
fi
