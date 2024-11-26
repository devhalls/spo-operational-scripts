#!/bin/bash
# Usage: scripts/start.sh
#
# Info:
#
#   - Launch a cardano node as a producer or relay.
#   - Assumes node has been installed.

source "$(dirname "$0")/../env"
source "$(dirname "$0")/common.sh"

if [ "${NODE_TYPE}" == "relay" ]; then
  print 'START' "Node starting as ${NODE_TYPE}"
  ${CNNODE} run --topology ${TOPOLOGY_PATH} --database-path ${NETWORK_DB_PATH} --socket-path ${NETWORK_SOCKET_PATH} --host-addr ${NODE_HOSTADDR} --port ${NODE_PORT} --config ${CONFIG_PATH}
elif [ "${NODE_TYPE}" == "producer" ]; then
  print 'START' "Node starting as ${NODE_TYPE}"
  ${CNNODE} run --topology ${TOPOLOGY_PATH} --database-path ${NETWORK_DB_PATH} --socket-path ${NETWORK_SOCKET_PATH} --host-addr ${NODE_HOSTADDR} --port ${NODE_PORT} --config ${CONFIG_PATH} --shelley-kes-key ${KES_KEY} --shelley-vrf-key ${VRF_KEY} --shelley-operational-certificate ${NODE_CERT}
else
  print 'START ERROR' "Node cannot run as ${NODE_TYPE}" $red
fi
