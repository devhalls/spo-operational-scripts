#!/bin/bash
# Usage: pool.sh (
#   generate_node_keys |
#   generate_kes_keys |
#   generate_vrf_keys |
#   generate_node_op_cert (kesPeriod <INT>) |
#   generate_pool_reg_cert (pledge <INT>) (cost <FLOAT>) (margin <FLOAT>) (metaUrl <STRING>) (--relay <STRING>) [--relay <STRING>] [--type <STRING<'DNS'|'IP'>>] |
#   generate_pool_dreg_cert (epoch <INT>) |
#   generate_metadata_hash (url <STRING>) |
#   rotate_kes (startPeriod <INT>) |
#   get_pool_id [format <STRING<'hex'|'bech32'>>] |
#   get_stake |
#   get_stats |
#   help [-h <BOOLEAN>]
# )
#
# Info:
#
#   - generate_node_keys) Generate node key pair and node counter certificate.
#   - generate_kes_keys) Generate node KES key pair.
#   - generate_vrf_keys) Generate node VRF key pair and sets permissions to 400.
#   - generate_node_op_cert) Generate node operational certificate. Requires the kesPeriod parameter.
#   - generate_pool_reg_cert) Generate pool registration certificate. Requires all params to generate the certificate.
#   - generate_pool_dreg_cert) Generate pool registration certificate.
#   - generate_metadata_hash) Generate pools metadata hash from the metadata.json url.
#   - rotate_kes) Rotate the pool KES keys. Requires KES startPeriod as the first parameter.
#   - get_pool_id) Output the pool ID to $POOL_ID and display it on screen. Optionally pass in the format, defaults to hex.
#   - get_stake) Retrieve pool stats from the blockchain.
#   - get_stats) Retrieve pool stats from js.cexplorer.io.
#   - help) View this files help. Default value if no option is passed.

source "$(dirname "$0")/common.sh"

pool_generate_node_keys() {
    exit_if_not_cold
    if [ -f $NODE_VKEY ]; then
        confirm "Node keys already exist! 'yes' to overwrite, 'no' to cancel"
    fi
    $CNCLI conway node key-gen \
        --cold-verification-key-file $NODE_VKEY \
        --cold-signing-key-file $NODE_KEY \
        --operational-certificate-issue-counter $NODE_COUNTER
    print 'POOL' "Node keys created at $NETWORK_PATH/keys" $green
}

pool_generate_node_kes_keys() {
    exit_if_not_cold
    if [ -f $KES_VKEY ]; then
        confirm "KES keys already exist! 'yes' to overwrite, 'no' to cancel"
    fi
    $CNCLI conway node key-gen-KES \
        --verification-key-file $KES_VKEY \
        --signing-key-file $KES_KEY
    print 'POOL' "Node KES keys created at $NETWORK_PATH/keys" $green
}

pool_generate_node_vrf_keys() {
    exit_if_not_producer
    if [ -f $VRF_VKEY ]; then
        confirm "VRF keys already exist! 'yes' to overwrite, 'no' to cancel"
    fi
    $CNCLI conway node key-gen-VRF \
        --verification-key-file $VRF_VKEY \
        --signing-key-file $VRF_KEY
    chmod 400 $VRF_KEY
    print 'POOL' "Node VRF keys created at $NETWORK_PATH/keys" $green
}

pool_generate_node_op_cert() {
    exit_if_not_cold
    exit_if_file_missing $KES_VKEY
    exit_if_file_missing $NODE_KEY
    exit_if_file_missing $NODE_COUNTER
    exit_if_empty "${1}" "1 kesPeriod"
    if [ -f $NODE_CERT ]; then
        confirm "Certificate already exist! 'yes' to overwrite, 'no' to cancel"
    fi
    $CNCLI conway node issue-op-cert \
        --kes-verification-key-file $KES_VKEY \
        --cold-signing-key-file $NODE_KEY \
        --operational-certificate-issue-counter $NODE_COUNTER \
        --kes-period ${1} \
        --out-file $NODE_CERT
    print 'POOL' "Node operational certificate created at $NODE_CERT" $green
}

pool_generate_pool_reg_cert() {
    exit_if_not_cold
    exit_if_file_missing $NODE_VKEY
    exit_if_file_missing $VRF_VKEY
    exit_if_file_missing $STAKE_VKEY
    exit_if_file_missing $STAKE_VKEY
    exit_if_file_missing $NODE_HOME/metadata/metadata.json
    exit_if_file_missing $NODE_HOME/metadata/metadataHash.txt
    exit_if_empty "${1}" "1 pledge"
    exit_if_empty "${2}" "2 cost"
    exit_if_empty "${3}" "3 margin"
    exit_if_empty "${4}" "4 metaUrl"
    exit_if_empty "$(get_option --relay "$@")" "--relay metaUrl"
    if [ -f $POOL_CERT ]; then
        confirm "Certificate already exist! 'yes' to overwrite, 'no' to cancel"
    fi
    local pledge="${1}"
    local cost="${2}"
    local margin="${3}"
    local metaUrl="${4}"
    local metaLocal=$NODE_HOME/metadata/metadata.json
    local metaHash=$(cat $NODE_HOME/metadata/metadataHash.txt)
    local relayType=$(get_option --type "$@")

    # Format the relays
    local relayArg=''
    local relays=$(get_option --relay "$@")
    read -ra relayParts <<< "$relays"
    if [ "${#relayParts[@]}" -eq 2 ]; then
        IFS=':' read -r ip port <<< "${relays[0]}"
        if [[ $relayType == *DNS* ]]; then
            relayArg+="--single-host-pool-relay $ip --pool-relay-port $port"
        else
            relayArg+="--pool-relay-ipv4 $ip --pool-relay-port $port"
        fi;
    else
        for ((i=0; i<${#relayParts[@]}; i++)); do
          if [[ "${relayParts[$i]}" == "--relay" ]]; then
            local hostPort="${relayParts[$((i+1))]}"
            IFS=':' read -r host port <<< "$hostPort"
            if [[ $relayType == *DNS* ]]; then
                relayArg+="--single-host-pool-relay $host --pool-relay-port $port "
            else
                relayArg+="--pool-relay-port $port --pool-relay-ipv4 $host "
            fi
          fi
        done
    fi;

    $CNCLI conway stake-pool registration-certificate \
        --cold-verification-key-file $NODE_VKEY \
        --vrf-verification-key-file $VRF_VKEY \
        --pool-pledge $pledge \
        --pool-cost $cost \
        --pool-margin $margin \
        --pool-reward-account-verification-key-file $STAKE_VKEY \
        --pool-owner-stake-verification-key-file $STAKE_VKEY \
        $NETWORK_ARG \
        $relayArg \
        --metadata-url $metaUrl \
        --metadata-hash $metaHash \
        --out-file $POOL_CERT
    print 'POOL' "Node registration certificate created at $POOL_CERT" $green
}

pool_generate_pool_dreg_cert() {
    exit_if_not_cold
    exit_if_file_missing $NODE_VKEY
    exit_if_empty "${1}" "1 epoch"
    if [ -f $POOL_DREG_CERT ]; then
        confirm "Certificate already exist! 'yes' to overwrite, 'no' to cancel"
    fi
    $CNCLI conway stake-pool deregistration-certificate \
        --cold-verification-key-file $NODE_VKEY \
        --epoch ${1} \
        --out-file $POOL_DREG_CERT
    print 'POOL' "Node de-registration certificate created at $POOL_DREG_CERT" $green
}

pool_generate_pool_meta_hash() {
    exit_if_not_producer
    exit_if_empty "${1}" "1 urls"
    local outputFileJson="$(dirname "$0")/../metadata/metadata.json"
    local outputFileHash="$(dirname "$0")/../metadata/metadataHash.txt"
    wget -O $outputFileJson ${1}
    exit_if_file_missing $outputFileJson

    $CNCLI conway stake-pool metadata-hash \
        --pool-metadata-file "${outputFileJson}" >"${outputFileHash}"
    print 'POOL' "Node metadata hash created at $NODE_HOME/metadata/metadataHash.txt" $green
}

pool_rotate_kes() {
    exit_if_not_cold
    exit_if_file_missing $NODE_KEY
    exit_if_file_missing $NODE_COUNTER
    exit_if_empty "${1}" "1 startPeriod"
    local startPeriod="${1}"
    confirm "Please confirm this the correct KES start period: $startPeriod"

    $CNCLI conway node key-gen-KES \
        --verification-key-file $KES_VKEY \
        --signing-key-file $KES_KEY
    $CNCLI conway node issue-op-cert \
        --kes-verification-key-file $KES_VKEY \
        --cold-signing-key-file $NODE_KEY \
        --operational-certificate-issue-counter $NODE_COUNTER \
        --kes-period $startPeriod \
        --out-file $NODE_CERT
    print 'POOL' "Copy node.cert and kes.skey back to your block producer node and restart it" $green
}

pool_get_pool_id() {
    exit_if_not_cold
    exit_if_file_missing $NODE_VKEY
    $CNCLI conway stake-pool id \
        --cold-verification-key-file $NODE_VKEY \
        --output-format ${1:-hex} >$POOL_ID
    echo "$(cat $POOL_ID)"
}

pool_get_stake() {
    exit_if_file_missing $POOL_ID
    $CNCLI query stake-snapshot --stake-pool-id $(cat $POOL_ID) \
        $NETWORK_ARG --socket-path $NETWORK_SOCKET_PATH
}

pool_get_stats() {
    local file=$NETWORK_PATH/stats/data-pool.prom
    rm $file && touch "$file"
    chmod +r $file
    local poolId=$(<"$POOL_ID")

    # Add data we can retrieve locally
    # - node version
    local version=$($(dirname "$0")/node.sh version)
    local majorMinor="${version%.*}"
    update_or_append $file "data_nodeVersion" "data_nodeVersion{version=\"$version\"} $majorMinor"

    # Add data we can retrieve locally with pool_id
    # - pool current epoch stake = set
    # - pool -2n epoch stake = mark
    # - pool middle current epoch stake = go
    exit_if_file_missing $POOL_ID
    local stakeSnapshot=$(pool_get_stake)
    local totalStake=$(echo "$stakeSnapshot" | jq -r ".total.stakeSet")
    local stakeSet=$(echo "$stakeSnapshot" | jq -r ".pools | to_entries[0].value.stakeSet")
    local stakeMark=$(echo "$stakeSnapshot" | jq -r ".pools | to_entries[0].value.stakeMark")
    local stakeGo=$(echo "$stakeSnapshot" | jq -r ".pools | to_entries[0].value.stakeGo")
    update_or_append $file "data_poolStakeSetAda" "data_poolStakeSetAda $stakeSet"
    update_or_append $file "data_poolStakeMarkAda" "data_poolStakeMarkAda $stakeMark"
    update_or_append $file "data_poolStakeGoAda" "data_poolStakeGoAda $stakeGo"

    # Add data we can't retrieve locally using Koios API
    # - Pool saturation, delegators, ledge
    # - Supply network totals, treasury, reserves
    if [ -n "$NODE_KOIOS_API" ]; then

        local poolApiResponse=$(curl -s -X POST "${NODE_KOIOS_API}pool_info" \
            -H "accept: application/json" \
            -H "content-type: application/json" \
            -d '{"_pool_bech32_ids": ["'"$poolId"'"]}')
        if echo "$poolApiResponse" | jq -e 'type == "array"' > /dev/null; then
            local poolApiData=$(echo "$poolApiResponse" | jq '.[-1]')
            update_or_append $file "data_poolPledge" "data_poolPledge $(echo "$poolApiData" | jq -r '.pledge')"
            update_or_append $file "data_poolFixedCost" "data_poolFixedCost $(echo "$poolApiData" | jq -r '.fixed_cost')"
            update_or_append $file "data_poolMargin" "data_poolMargin $(echo "$poolApiData" | jq -r '.margin')"
            update_or_append $file "data_poolLivePledge" "data_poolLivePledge $(echo "$poolApiData" | jq -r '.live_pledge')"
            update_or_append $file "data_poolActiveStake" "data_poolActiveStake $(echo "$poolApiData" | jq -r '.active_stake')"
            update_or_append $file "data_poolLiveStake" "data_poolLiveStake $(echo "$poolApiData" | jq -r '.live_stake')"
            update_or_append $file "data_poolLiveDelegators" "data_poolLiveDelegators $(echo "$poolApiData" | jq -r '.live_delegators')"
            update_or_append $file "data_poolLiveSaturation" "data_poolLiveSaturation $(echo "$poolApiData" | jq -r '.live_saturation')"
            update_or_append $file "data_poolLivePledge" "data_poolLivePledge $(echo "$poolApiData" | jq -r '.live_pledge')"
            update_or_append $file "data_poolBlockCount" "data_poolBlockCount $(echo "$poolApiData" | jq -r '.block_count')"
        fi
        local totalsApiResponse=$(curl -s "${NODE_KOIOS_API}totals?limit=1")
        if echo "$totalsApiResponse" | jq -e 'type == "array"' > /dev/null; then
            local totalsApiData=$(echo "$totalsApiResponse" | jq '.[-1]')
            update_or_append $file "data_totalCirculation" "data_totalCirculation $(echo "$totalsApiData" | jq -r '.circulation')"
            update_or_append $file "data_totalSupply" "data_totalSupply $(echo "$totalsApiData" | jq -r '.supply')"
            update_or_append $file "data_totalTreasury" "data_totalTreasury $(echo "$totalsApiData" | jq -r '.treasury')"
            update_or_append $file "data_totalReserves" "data_totalReserves $(echo "$totalsApiData" | jq -r '.reserves')"
        fi
    fi
}

case $1 in
    generate_node_keys) pool_generate_node_keys ;;
    generate_kes_keys) pool_generate_node_kes_keys ;;
    generate_vrf_keys) pool_generate_node_vrf_keys ;;
    generate_node_op_cert) pool_generate_node_op_cert "${@:2}" ;;
    generate_pool_reg_cert) pool_generate_pool_reg_cert "${@:2}" ;;
    generate_pool_dreg_cert) pool_generate_pool_dreg_cert "${@:2}" ;;
    generate_pool_meta_hash) pool_generate_pool_meta_hash "${@:2}" ;;
    rotate_kes) pool_rotate_kes "${@:2}" ;;
    get_pool_id) pool_get_pool_id "${@:2}" ;;
    get_info) pool_get_info ;;
    get_stake) pool_get_stake ;;
    get_stats) pool_get_stats ;;
    help) help "${2:-"--help"}" ;;
    *) help "${1:-"--help"}" ;;
esac
