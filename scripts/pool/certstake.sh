#!/bin/bash
# Usage: scripts/pool/certstake.sh <lovelace>
#
# Info:
#
#   - Generate your stake certificate
#   - Requires the deposit amount to be passed in lovelace minimum 2000000

source "$(dirname "$0")/../../env"
source "$(dirname "$0")/../common.sh"
lovelace=${1}

$CNCLI conway stake-address registration-certificate \
    --stake-verification-key-file $STAKE_VKEY \
    --key-reg-deposit-amt $lovelace \
    --out-file $STAKE_CERT
