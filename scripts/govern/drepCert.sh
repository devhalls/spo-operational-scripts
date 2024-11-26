#!/bin/bash
# Usage: scripts/govern/drepCert.sh <url>
#
# Info:
#
#   - Generate a DRep certificate

source "$(dirname "$0")/../../env"
source "$(dirname "$0")/../common.sh"
url=${1}
temp=$NETWORK_PATH/temp/drep.json

if [ -f $DREP_CERT ]; then
  print "DREP" "DRep certificate already exists, delete the existing key to generate a new one" $red
  exit 1
fi

wget -O $temp $url

deposit=$($CNCLI conway query protocol-parameters $NETWORK_ARG --socket-path $NETWORK_SOCKET_PATH | jq .dRepDeposit)
hash=$($CNCLI conway governance drep metadata-hash --drep-metadata-file $temp)

print "DREP" "DRep deposit: $deposit"
print "DREP" "DRep metadata URL: $url"
print "DREP" "DRep metadata hash: $hash"

$CNCLI conway governance drep registration-certificate \
   --drep-verification-key-file $DREP_VKEY \
   --key-reg-deposit-amt $deposit \
   --drep-metadata-url $url \
   --drep-metadata-hash $hash \
   --out-file $DREP_CERT

rm $temp
