#!/bin/bash
# Usage: pool.sh [
#   action [govActionId] [govActionIndex] [decision] [?keyFile] |
#   vote [govActionId] |
#   drep_id [?format] |
#   drep_keys |
#   drep_cert [url] |
#   help [?-h]
# ]
#
# Info:
#
#   - action) Query the blockchain for a gov action info. Expects a govActionId param.
#   - vote) Cast a vote for the passed params. keyFile defaults to 'node' assuming a pool vote. Can be 'node' | 'drep' | 'cc'.
#   - drep_id) Retrieve the dreps id. Optionally pass the format, defaults to bech32.
#   - drep_keys) Generate DRep keys.
#   - drep_cert) Generate DRep certificate expecting the passed url for the drep metadata json.
#   - help) View this files help. Default value if no option is passed.

source "$(dirname "$0")/../env"
source "$(dirname "$0")/common.sh"

govern_action() {
  exit_if_cold
  govActionId=${1}
  $CNCLI conway query gov-state $NETWORK_ARG --socket-path $NETWORK_SOCKET_PATH |
  jq -r --arg govActionId "$govActionId" '.proposals | to_entries[] | select(.value.actionId.txId | contains($govActionId)) | .value'
}

govern_vote() {
  exit_if_not_cold
  govActionId=${1}
  govActionIndex=${2}
  decision=${3}
  keyFile=${4:-'node'}
  outputPath=$NETWORK_PATH/temp/vote.raw

  if [ "$decision" != "yes" ] && [ "$decision" != "no" ] && [ "$decision" != "abstain" ] ; then
    print 'GOVERN' "Incorrect decision value $decision: allowed values 'yes' | 'no' | 'abstain'" $red
    exit 1
  fi

  verification_arg=
    case $keyFile in
      "node") verification_arg="--cold-verification-key-file $NODE_VKEY";;
      "drep") verification_arg="--drep-verification-key-file $DREP_VKEY";;
      "cc") verification_arg="--cc-hot-verification-key-file $CC_HOT_VKEY";;
    esac

  $CNCLI conway governance vote create \
    --$decision \
    --governance-action-tx-id "$govActionId" \
    --governance-action-index "$govActionIndex" \
    $verification_arg \
    --out-file $outputPath

  print 'GOVERN' "Vote cast for $keyFile. Voted: $decision. Output: $outputPath" $green
}

govern_drep_id() {
  exit_if_not_producer
  format="${1:-"bech32"}"
  $CNCLI conway governance drep id \
    --drep-verification-key-file $DREP_VKEY \
    --output-format $format \
    --out-file $DREP_ID
  print "GOVERN" "ID: $(cat $DREP_ID)" $green
}

govern_generate_drep_keys() {
  exit_if_not_cold
  if [ -f $DREP_KEY ]; then
    confirm "DRep keys already exist! 'yes' to overwrite, 'no' to cancel"
  fi
  $CNCLI conway governance drep key-gen \
    --verification-key-file $DREP_VKEY \
    --signing-key-file $DREP_KEY
}

govern_generate_drep_cert() {
  exit_if_not_cold
  if [ -f $DREP_CERT ]; then
    confirm "DRep certificate already exists! 'yes' to overwrite, 'no' to cancel"
  fi

  url=${1}
  temp=$NETWORK_PATH/temp/drep.json

  wget -O $temp $url
  if [ $? -eq 0 ]; then
    deposit=$($CNCLI conway query protocol-parameters $NETWORK_ARG --socket-path $NETWORK_SOCKET_PATH | jq .dRepDeposit)
    hash=$($CNCLI conway governance drep metadata-hash --drep-metadata-file $temp)

    print "GOVERN" "DRep deposit: $deposit"
    print "GOVERN" "DRep metadata URL: $url"
    print "GOVERN" "DRep metadata hash: $hash"

    $CNCLI conway governance drep registration-certificate \
       --drep-verification-key-file $DREP_VKEY \
       --key-reg-deposit-amt $deposit \
       --drep-metadata-url $url \
       --drep-metadata-hash $hash \
       --out-file $DREP_CERT

    rm $temp
  else
    print "GOVERN" "Unable to download drep.json from passed url" $red
  fi
}

case $1 in
  action) govern_action "${@:2}" ;;
  vote) govern_vote "${@:2}" ;;
  drep_id) govern_drep_id "${@:2}" ;;
  drep_keys) govern_generate_drep_keys ;;
  drep_cert) govern_generate_drep_cert "${@:2}" ;;
  help) help "${2:-"--help"}" ;;
  *) help "${1:-"--help"}" ;;
esac
