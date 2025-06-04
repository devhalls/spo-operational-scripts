#!/bin/bash
# Usage: govern.sh (
#   action (govActionId <STRING>) |
#   vote (govActionId <STRING>) (govActionIndex <INT>) (decision <STRING>) [keyFile <STRING>] |
#   vote_json (govActionId <STRING>) (govActionIndex <INT>) (decision <STRING>) (url <STRING>) |
#   drep_id [format <STRING<'--output-bech32'|'--output-hex'>>] |
#   drep_id_CIP129 [type <STRING<'drep1'|'drep_script1'|'cc_hot1'|'cc_hot_script1'|'cc_cold1'|'cc_cold_script1'>>]
#   drep_keys |
#   drep_cert (url <STRING>) [deposit <BOOLEAN>] |
#   cc_cold_keys |
#   cc_cold_hash |
#   cc_hot_keys |
#   cc_cert |
#   help [-h <BOOLEAN>]
# )
#
# Info:
#
#   - action) Query the blockchain for a gov action info by its tx ID. Expects a govActionId param.
#   - vote) Cast a vote for the passed params. keyFile defaults to 'node' assuming a pool vote. Can be 'node' | 'drep' | 'cc'.
#   - vote_json) Cast a vote for the passed params. Same as vote but includes anchor url and json format submission.
#   - drep_id) Retrieve the DReps id. Optionally pass the format, defaults to bech32.
#   - drep_keys) Generate DRep keys.
#   - drep_cert) Generate DRep certificate expecting the passed url for the drep metadata json. Optionally pass second param to update-certificate.
#   - cc_cold_keys) Generate CC cold keys.
#   - cc_cold_hash) Generate CC cold hash.
#   - cc_hot_keys) Generate CC hot keys.
#   - cc_cert) Generate CC certificate.
#   - help) View this files help. Default value if no option is passed.

source "$(dirname "$0")/common.sh"

govern_action() {
    exit_if_cold
    exit_if_empty "${1}" "1 govActionId"
    local govActionId=${1}
    echo $govActionId
    $CNCLI conway query gov-state $NETWORK_ARG --socket-path $NETWORK_SOCKET_PATH |
        jq -r --arg govActionId "$govActionId" '.proposals | to_entries[] | select(.value.actionId.txId | contains($govActionId)) | .value'
}

govern_state() {
    exit_if_cold
    $CNCLI conway query drep-state --drep-key-hash $(govern_drep_id hex) $NETWORK_ARG --socket-path $NETWORK_SOCKET_PATH
}

govern_vote() {
    exit_if_not_cold
    exit_if_empty "${1}" "1 govActionId"
    exit_if_empty "${2}" "2 govActionIndex"
    exit_if_empty "${3}" "3 decision"
    local govActionId=${1}
    local govActionIndex=${2}
    local decision=${3}
    local keyFile=${4:-'node'}
    local outputPath=$NETWORK_PATH/temp/vote.raw
    if [ "$decision" != "yes" ] && [ "$decision" != "no" ] && [ "$decision" != "abstain" ]; then
        print 'GOVERN' "Incorrect decision value $decision: allowed values 'yes' | 'no' | 'abstain'" $red
        exit 1
    fi

    local verification_arg=
        case $keyFile in
            "node") verification_arg="--cold-verification-key-file $NODE_VKEY" ;;
            "drep") verification_arg="--drep-verification-key-file $DREP_VKEY" ;;
            "cc") verification_arg="--cc-hot-verification-key-file $CC_HOT_VKEY" ;;
        esac

    $CNCLI conway governance vote create \
        --$decision \
        --governance-action-tx-id "$govActionId" \
        --governance-action-index "$govActionIndex" \
        $verification_arg \
        --out-file $outputPath

    print 'GOVERN' "Vote created for $keyFile. Voted: $decision. Output: $outputPath" $green
}

govern_vote_json() {
    # @todo test this vote json function?
    exit_if_not_cold
    exit_if_empty "${1}" "1 govActionId"
    exit_if_empty "${2}" "2 govActionIndex"
    exit_if_empty "${3}" "3 decision"
    exit_if_empty "${4}" "4 url"
    local govActionId=${1}
    local govActionIndex=${2}
    local decision=${3}
    local url=${4}
    local urlFile=$NETWORK_PATH/temp/rationale.jsonld
    local voteJson=$NETWORK_PATH/temp/vote.json
    local outputPath=$NETWORK_PATH/temp/vote.wit
    curl -L -o "$urlFile" "$url"
    local actionType=$(govern_action "$govActionId" | jq -r '.proposalProcedure.govAction.tag')
    local urlHash=$($CNCLI hash anchor-data --file-text "$urlFile")
    case "$actionType" in
      MotionNoConfidence)  actionType="motion_no_confidence" ;;
      CommitteeChange)     actionType="committee_update" ;;
      ConstitutionUpdate)  actionType="constitution_update" ;;
      HardForkInitiation)  actionType="hard_fork_initiation" ;;
      ParameterChange)     actionType="parameter_change" ;;
      TreasuryWithdrawals) actionType="treasury_withdrawal" ;;
      InfoAction)          actionType="info" ;;
    esac

    # Make the json file
    jq -n \
      --arg drep "$(govern_drep_id hex)" \
      --arg txid "$govActionId" \
      --argjson index $govActionIndex \
      --arg vote "$decision" \
      --arg type "$actionType" \
      --arg url "$url" \
      --arg hash "$urlHash" \
      '{
        "61284": [
          {
            "govActionId": {
              "type": $type,
              "txId": $txid,
              "govActionIndex": $index
            },
            "vote": $vote,
            "anchor": {
              "url": $url,
              "dataHash": $hash
            }
          }
        ]
      }' > $voteJson

      cat $voteJson
}

govern_drep_id() {
    exit_if_not_producer
    local format="${1:-"--output-bech32"}"
    $CNCLI conway governance drep id \
        --drep-verification-key-file $DREP_VKEY \
        $format \
        --out-file $DREP_ID
    cat $DREP_ID
}

govern_drep_id_CIP129() {
    exit_if_not_producer
    local type=${1:-drep1}
	local hexId=$($CNBECH32 <<< "$(govern_drep_id)")
	case "${type}" in
		"drep1"*) formatted=$($CNBECH32 "drep" <<< "22${hexId}");;
		"drep_script1"*) formatted=$($CNBECH32 "drep" <<< "23${hexId}");;
		"cc_hot1"*) formatted=$($CNBECH32 "cc_hot" <<< "02${hexId}");;
		"cc_hot_script1"*) formatted=$($CNBECH32 "cc_hot" <<< "03${hexId}");;
		"cc_cold1"*) formatted=$($CNBECH32 "cc_cold" <<< "12${hexId}");;
		"cc_cold_script1"*) formatted=$($CNBECH32 "cc_cold" <<< "13${hexId}");;
		*) print "ERROR" "Unable to convert ${type}"; exit 1 ;;
	esac
    echo "${formatted}"
}

govern_generate_drep_keys() {
    exit_if_not_cold
    if [ -f $DREP_VKEY ]; then
        confirm "DRep keys already exist! 'yes' to overwrite, 'no' to cancel"
    fi
    $CNCLI conway governance drep key-gen \
        --verification-key-file $DREP_VKEY \
        --signing-key-file $DREP_KEY
    print 'GOVERN' "DRep keys created at $NETWORK_PATH/keys" $green
}

govern_generate_drep_cert() {
    exit_if_not_cold
    exit_if_file_missing $DREP_VKEY
    exit_if_file_missing $NODE_HOME/metadata/drep.json
    if [ -f $DREP_CERT ]; then
        confirm "DRep certificate already exists! 'yes' to overwrite, 'no' to cancel"
    fi
    local url=${1}
    local update=${2}
    local file=$NODE_HOME/metadata/drep.json
    local hash=$($CNCLI conway governance drep metadata-hash --drep-metadata-file $file)
    print "GOVERN" "DRep metadata URL: $url"
    print "GOVERN" "DRep metadata hash: $hash"

    if [ -z "$update" ]; then
        deposit=${2:-$($CNCLI conway query protocol-parameters $NETWORK_ARG --socket-path $NETWORK_SOCKET_PATH | jq .dRepDeposit)}
        print "GOVERN" "DRep deposit: $deposit"
        $CNCLI conway governance drep registration-certificate \
            --drep-verification-key-file $DREP_VKEY \
            --key-reg-deposit-amt $deposit \
            --drep-metadata-url $url \
            --drep-metadata-hash $hash \
            --out-file $DREP_CERT
    else
        $CNCLI conway governance drep update-certificate \
            --drep-verification-key-file $DREP_VKEY \
            --drep-metadata-url $url \
            --drep-metadata-hash $hash \
            --out-file $DREP_CERT
    fi

    print 'GOVERN' "DRep certificate created at $DREP_CERT" $green
}

govern_generate_cc_cold_keys() {
    exit_if_not_cold
    if [ -f $CC_COLD_KEY ]; then
        confirm "CC cold keys already exist! 'yes' to overwrite, 'no' to cancel"
    fi
    $CNCLI conway governance committee key-gen-cold \
      --cold-verification-key-file $CC_COLD_VKEY \
      --cold-signing-key-file $CC_COLD_KEY
    print 'GOVERN' "CC cold keys created at $NETWORK_PATH/keys" $green
}

govern_generate_cc_cold_hash() {
    exit_if_not_cold
    exit_if_file_missing $CC_COLD_VKEY
    $CNCLI conway governance committee key-hash \
      --verification-key-file $CC_COLD_VKEY > $CC_COLD_HASH
    print 'GOVERN' "CC cold hash created at $NETWORK_PATH/keys" $green
}

govern_generate_cc_hot_keys() {
    exit_if_not_cold
    if [ -f $CC_HOT_KEY ]; then
        confirm "CC hot keys already exist! 'yes' to overwrite, 'no' to cancel"
    fi
    $CNCLI conway governance committee key-gen-hot \
      --verification-key-file $CC_HOT_VKEY \
      --signing-key-file $CC_HOT_KEY
    print 'GOVERN' "CC hot keys created at $NETWORK_PATH/keys" $green
}

govern_generate_cc_hot_hash() {
    exit_if_not_cold
    exit_if_file_missing $CC_HOT_VKEY
    $CNCLI conway governance committee key-hash \
      --verification-key-file $CC_HOT_VKEY > $CC_HOT_HASH
    print 'GOVERN' "CC cold hash created at $NETWORK_PATH/keys" $green
}

govern_generate_cc_cert() {
    exit_if_not_cold
    exit_if_file_missing $CC_COLD_VKEY
    exit_if_file_missing $CC_HOT_VKEY
    if [ -f $CC_CERT ]; then
        confirm "CC certificate already exist! 'yes' to overwrite, 'no' to cancel"
    fi
    $CNCLI conway governance committee create-hot-key-authorization-certificate \
      --cold-verification-key-file $CC_COLD_VKEY \
      --hot-verification-key-file $CC_HOT_VKEY \
      --out-file $CC_CERT
    print 'GOVERN' "CC certificate created at $CC_CERT" $green
}

case $1 in
    action) govern_action "${@:2}" ;;
    state) govern_state ;;
    vote) govern_vote "${@:2}" ;;
    vote_json) govern_vote_json "${@:2}" ;;
    drep_id) govern_drep_id "${@:2}" ;;
    drep_id_CIP129) govern_drep_id_CIP129 "${@:2}" ;;
    drep_keys) govern_generate_drep_keys ;;
    drep_cert) govern_generate_drep_cert "${@:2}" ;;
    cc_cold_keys) govern_generate_cc_cold_keys ;;
    cc_cold_hash) govern_generate_cc_cold_hash ;;
    cc_hot_keys) govern_generate_cc_hot_keys ;;
    cc_hot_hash) govern_generate_cc_hot_hash ;;
    cc_cert) govern_generate_cc_cert ;;
    help) help "${2:-"--help"}" ;;
    *) help "${1:-"--help"}" ;;
esac
