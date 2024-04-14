#!/bin/bash

# Info : Generate vrf key pair.
#      : Expects env with set variables.
# Use  : cd $NODE_HOME
#      : scripts/gen/keyvrf.sh

export $(xargs < env)
NETWORK_PATH=${NODE_HOME}/networks/${NODE_NETWORK}
VRF_VKEY=${NETWORK_PATH}/keys/vrf.vkey
VRF_SKEY=${NETWORK_PATH}/keys/vrf.skey

cardano-cli node key-gen-VRF \
    --verification-key-file $VRF_VKEY \
    --signing-key-file $VRF_SKEY
    
chmod 400 $VRF_SKEY
