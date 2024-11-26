#!/bin/bash
# Usage: scripts/govern/vote.sh <govActionId> <govActionIndex> <'yes' | 'no' | 'abstain'> <keyFile 'node.vkey' | 'drep.vkey' | 'cc-hot.vkey'>
#
# Info:
#
#   - Create a vote with the passed decision 'yes' | 'no' | 'abstain'
#   - Uses pools $NODE_VKEY by default

source "$(dirname "$0")/../../env"
source "$(dirname "$0")/../common.sh"
govActionId=${1}
govActionIndex=${2}
decision=${3}
keyFile=${4:-'node.vkey'}
outputPath=$NETWORK_PATH/temp/vote.raw

if [ "$decision" != "yes" ] && [ "$decision" != "no" ] && [ "$decision" != "abstain" ] ; then
  print 'VOTE' "Incorrect decision value $decision: allowed values 'yes' | 'no' | 'abstain'" $red
  exit 1
fi

verification_arg=
case $keyFile in
    "node.vkey") verification_arg="--cold-verification-key-file";;
    "drep.vkey") verification_arg="--drep-verification-key-file";;
    "cc-hot.vkey") verification_arg="--cc-hot-verification-key-file";;
esac

$CNCLI conway governance vote create \
  --$decision \
  --governance-action-tx-id "$govActionId" \
  --governance-action-index "$govActionIndex" \
  $verification_arg $NETWORK_PATH/keys/$keyFile \
  --out-file $outputPath

print 'VOTE' "File made with $keyFile output: $outputPath" $green
