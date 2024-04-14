#!/bin/bash

# Info : Launch a cardano node as a producer or relay.
#      : Assumes all node configs and keys are present at NODE_HOME.
#      : Expects env with set variables.
# Use  : cd $NODE_HOME
#      : scripts/start.sh <sanchonet | preview | preprod | mainnet>

source "$(dirname "$0")/../networks/${2:-"preview"}/env"

typology=${NETWORK_PATH}/topology.json
config=${NETWORK_PATH}/config.json

# Run as a relay.
if [ "${NODE_TYPE}" == "relay" ]; then
  echo "[START] Node starting as ${NODE_TYPE}"
  ${CNCLI} run --topology ${typology} --database-path ${NETWORK_DB_PATH} --socket-path ${NETWORK_SOCKET_PATH} --host-addr ${NODE_HOSTADDR} --port ${NODE_PORT} --config ${config}

# Run as a producer.
elif [ "${NODE_TYPE}" == "producer" ]; then
  echo "[START] Node starting as ${NODE_TYPE}"
  ${CNCLI} run --topology ${typology} --database-path ${NETWORK_DB_PATH} --socket-path ${NETWORK_SOCKET_PATH} --host-addr ${NODE_HOSTADDR} --port ${NODE_PORT} --config ${config} --shelley-kes-key ${KES_KEY} --shelley-vrf-key ${VRF_KEY} --shelley-operational-certificate ${NODE_CERT}

# Cannot run.
else
  echo "[START ERROR] Node cannot run as ${NODE_TYPE}"
fi
