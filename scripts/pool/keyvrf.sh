#!/bin/bash
# Usage: scripts/pool/keyvrf.sh
#
# Info:
#
#   - Generate vrf key pair
#   - Sets appropriate permissions on the skey

source "$(dirname "$0")/../../env"
source "$(dirname "$0")/../common.sh"

$CNCLI conway node key-gen-VRF \
    --verification-key-file $VRF_VKEY \
    --signing-key-file $VRF_KEY
    
chmod 400 $VRF_KEY
