#!/bin/bash

source "$(dirname "$0")/../networks/${1}/env"
source "$(dirname "$0")/common/common.sh"
help 5 1 ${@} || exit

typology=${NETWORK_PATH}/topology.json
config=${NETWORK_PATH}/config.json

# Run as a relay.
if [ "${NODE_TYPE}" == "relay" ]; then
  echo "[START] Node starting as ${NODE_TYPE}"
  ${CNNODE} run --topology ${typology} --database-path ${NETWORK_DB_PATH} --socket-path ${NETWORK_SOCKET_PATH} --host-addr ${NODE_HOSTADDR} --port ${NODE_PORT} --config ${config}

# Run as a producer.
elif [ "${NODE_TYPE}" == "producer" ]; then
  echo "[START] Node starting as ${NODE_TYPE}"
  ${CNNODE} run --topology ${typology} --database-path ${NETWORK_DB_PATH} --socket-path ${NETWORK_SOCKET_PATH} --host-addr ${NODE_HOSTADDR} --port ${NODE_PORT} --config ${config} --shelley-kes-key ${KES_KEY} --shelley-vrf-key ${VRF_KEY} --shelley-operational-certificate ${NODE_CERT}

# Cannot run.
else
  echo "[START ERROR] Node cannot run as ${NODE_TYPE}"
fi
