#!/bin/bash

source "$(dirname "$0")/../networks/${1}/env"
source "$(dirname "$0")/common/common.sh"
help 5 1 ${@} || exit

# Run as a relay.
if [ "${NODE_TYPE}" == "relay" ]; then
  print 'START' "Node starting as ${NODE_TYPE}"
  ${CNNODE} run --topology ${TOPOLOGY_PATH} --database-path ${NETWORK_DB_PATH} --socket-path ${NETWORK_SOCKET_PATH} --host-addr ${NODE_HOSTADDR} --port ${NODE_PORT} --config ${CONFIG_PATH}

# Run as a producer.
elif [ "${NODE_TYPE}" == "producer" ]; then
  print 'START' "Node starting as ${NODE_TYPE}"
  ${CNNODE} run --topology ${TOPOLOGY_PATH} --database-path ${NETWORK_DB_PATH} --socket-path ${NETWORK_SOCKET_PATH} --host-addr ${NODE_HOSTADDR} --port ${NODE_PORT} --config ${CONFIG_PATH} --shelley-kes-key ${KES_KEY} --shelley-vrf-key ${VRF_KEY} --shelley-operational-certificate ${NODE_CERT}

# Cannot run.
else
  print 'START ERROR' "Node cannot run as ${NODE_TYPE}" $red
fi
