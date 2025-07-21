#!/bin/bash
# Usage: query.sh (
#   tip [name <STRING>] |
#   params [name <STRING>] |
#   state (name <STRING>) |
#   metrics [name <STRING>] |
#   config (name <STRING>) |
#   key (name <STRING>) |
#   keys (format <STRING<'table'>>)|
#   kes |
#   kes_period |
#   uxto [address <STRING>] |
#   leader [period <STRING<'current'|'next'>>] |
#   rewards [name <STRING>] |
#   help [-h <BOOLEAN>]
# )
#
# Info:
#
#   - tip) Query the blockchain tip. Optionally pass a param name to view only this value.
#   - params) Query the blockchain protocol parameters and saves these to $NETWORK_PATH/params.json. Optionally pass a param name to view only this value.
#   - state) Query the blockchain ledger-state and saves these to $NETWORK_PATH/ledger.json. Optionally pass a param name to view only this value. Very large so we only create it if it does not exist (will become out of date if left as is, you must periodically delete the ledger.json file.)
#   - metrics) Query the prometheus metrics. Optionally pass a param name to view only this value.
#   - config) Echo the contents of any config file located in $NETWORK_PATH. Pass the file name you wish to read.
#   - key) Echo the contents of any file located in $NETWORK_PATH/keys. Pass the file name you wish to read.
#   - keys) Echo the contents of all files located in $NETWORK_PATH/keys.
#   - kes) Query the current $NODE_CERT on chain kes state.
#   - kes_period) Query the kes period params. Useful when generating pool certificates.
#   - uxto) Query the uxto for an address. Defaults to $PAYMENT_ADDR if non is passed.
#   - leader) Run the pool leader slot query. Pass the period to choose which epoch to query ['next' | 'current' ].
#   - rewards) Query stake address info. Optionally pass a param name to view only this value.
#   - help) View this files help. Default value if no option is passed.

source "$(dirname "$0")/common.sh"

query_tip() {
    exit_if_cold
    if [ "$1" ]; then
        $CNCLI conway query tip $NETWORK_ARG --socket-path $NETWORK_SOCKET_PATH | jq -r ".$1" | tr -d '\n\r'
    else
        $CNCLI conway query tip $NETWORK_ARG --socket-path $NETWORK_SOCKET_PATH
        echo ''
    fi
}

query_params() {
    exit_if_cold
    $CNCLI conway query protocol-parameters $NETWORK_ARG --socket-path $NETWORK_SOCKET_PATH \
        --out-file $NETWORK_PATH/params.json
    if [ "$1" ]; then
        cat $NETWORK_PATH/params.json | jq -r ".$1" | tr -d '\n\r'
    else
        cat $NETWORK_PATH/params.json
        echo ''
    fi
}

query_state() {
    exit_if_cold
    # if [ ! -f $NETWORK_PATH/ledger.json ]; then
        $CNCLI conway query ledger-state $NETWORK_ARG --socket-path $NETWORK_SOCKET_PATH > ledger.txt
    # fi
    exit 1
    if [ "$1" ]; then
        cat $NETWORK_PATH/ledger.txt | jq -r ".$1" | tr -d '\n\r'
    else
        cat $NETWORK_PATH/ledger.txt
        echo ''
    fi
}

query_metrics() {
    exit_if_cold
    if [ "$1" ]; then
        curl -s localhost:12798/metrics | grep "$1"
    else
        curl -s localhost:12798/metrics
    fi
}

query_config() {
    exit_if_file_missing $NETWORK_PATH/$1
    cat $NETWORK_PATH/$1
    echo ''
}

query_key() {
    exit_if_file_missing $NETWORK_PATH/keys/$1
    cat $NETWORK_PATH/keys/$1
    echo ''
}

query_keys() {
    local displayType=${1:-table}
    if [[ $displayType == "table" ]]; then
        printf "|%-22s|%-52s|\n" "$(printf '%.0s-' {1..22})" "$(printf '%.0s-' {1..52})"
        printf "| %-20s | %-50s |\n" "Filename" "Contents"
        printf "|%-22s|%-52s|\n" "$(printf '%.0s-' {1..22})" "$(printf '%.0s-' {1..52})"
        for file in $NETWORK_PATH/keys/*; do
            if [[ ! -f "$file" ]]; then
                continue
            fi
            filename=$(basename "$file")
            raw_content=$(<"$file")
            if echo "$raw_content" | jq empty 2>/dev/null; then
                content=$(echo "$raw_content" | jq -c .)
            else
                content=$(head -n 1 "$file" | tr -d '\n')
            fi
            # Print row and truncate if too long
            printf "| %-20s | %-50.50s |\n" "$filename" "$content"
        done
        printf "|%-22s|%-52s|\n" "$(printf '%.0s-' {1..22})" "$(printf '%.0s-' {1..52})"
        exit 1
    fi

    if stat --version >/dev/null 2>&1; then
        get_modified() { stat -c "%y" "$1" | cut -d'.' -f1; }
        get_perms()  { stat -c "%A" "$1"; }
        get_size()   { stat -c "%s" "$1"; }
    else
        get_modified() { stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$1"; }
        get_perms()  { stat -f "%Sp" "$1"; }
        get_size()   { stat -f "%z" "$1"; }
    fi

    for file in $NETWORK_PATH/keys/*; do
        [ -f "$file" ] || continue

        local filename=$(basename "$file")
        local modified=$(get_modified "$file")
        local perms=$(get_perms "$file")
        local size=$(get_size "$file")
        local content=$(<"$file")
        echo "|==============================================|"
        echo "| 📄 $filename ($size bytes) ($modified)"
        echo "| 🔐 $perms"
        echo "|----------------------------------------------|"
        echo
        if echo "$content" | jq empty 2>/dev/null; then
            echo "$content" | jq
        else
            echo "$content"
        fi
        echo
    done
}

query_kes() {
    exit_if_not_producer
    exit_if_file_missing $NODE_CERT
    $CNCLI conway query kes-period-info $NETWORK_ARG --socket-path $NETWORK_SOCKET_PATH \
        --op-cert-file $NODE_CERT
}

query_kes_period() {
    exit_if_cold
    exit_if_file_missing $NETWORK_PATH/shelley-genesis.json
    local slotsPerKESPeriod=$(cat $NETWORK_PATH/shelley-genesis.json | jq -r '.slotsPerKESPeriod')
    local slotNo=$(query_tip slot)
    local kesPeriod=$(($slotNo / $slotsPerKESPeriod))
    echo "slotsPerKESPeriod: $slotsPerKESPeriod"
    echo "currentSlot: $slotNo"
    echo "kesPeriod: $kesPeriod"
}

query_uxto() {
    exit_if_cold
    exit_if_file_missing $PAYMENT_ADDR
    $CNCLI conway query utxo --output-text $NETWORK_ARG --socket-path $NETWORK_SOCKET_PATH \
        --address ${1:-"$(cat $PAYMENT_ADDR)"}
}

query_leader() {
    exit_if_not_producer
    exit_if_file_missing $POOL_ID

    # Set the query period and targetEpoch
    period="--${1:-"next"}"
    targetEpoch=$(query_tip epoch)
    if [[ $period != '--next' && $period != '--current' ]]; then
        print 'ERROR' "Leadership schedule incorrect period value: $period"
        exit 0
    fi
    if [ $period == '--next' ]; then targetEpoch=$(($targetEpoch + 1)); fi

    # Set file paths and get the poolId
    local outputPath=$NETWORK_PATH/logs
    local tempFilePath=$outputPath/$targetEpoch.txt
    local csvFile=$outputPath/slots.csv
    local grafanaLocation=/usr/share/grafana
    local poolId=$(<$POOL_ID)

    # Run the leadership-schedule query
    print 'QUERY' "Leadership schedule starting, please wait..."
    $CNCLI query leadership-schedule $NETWORK_ARG --socket-path $NETWORK_SOCKET_PATH \
        --genesis $NETWORK_PATH/shelley-genesis.json \
        --stake-pool-id $poolId \
        --vrf-signing-key-file $VRF_KEY \
        $period >$tempFilePath
    if [ $? -ne 0 ]; then
        print 'ERROR' "Leadership schedule failed to run" $red
        exit 0
    fi

    # Create the CSV file if it does not exist
    if [ ! -f $csvFile ]; then
        echo 'Time,Slot,No,Epoch' >$csvFile 2>/dev/null
    fi

    # Process the output file adding values to $csvFile, echo the result, and copy to grafana folder if it exists
    if [ -f $tempFilePath ]; then
        echo "$(tail -n +3 $tempFilePath)" >$tempFilePath
        sed -i "s/\$/ $targetEpoch/" $tempFilePath
        local content=$(awk '{print $2,$3","$1","NR","$5}' $tempFilePath)
        grep -qxF "$content" $csvFile || echo "$content" >>$csvFile
        echo "$content"
        if [ -d $grafanaLocation ]; then
            sudo cp $csvFile $grafanaLocation/slots.csv
        fi
        rm $tempFilePath
    else
        print 'ERROR' "Leadership schedule failed to run" $red
        exit 0
    fi
}

query_rewards() {
    data=$(
        $CNCLI conway query stake-address-info $NETWORK_ARG --socket-path $NETWORK_SOCKET_PATH \
            --address $(<$STAKE_ADDR) | jq '.[0]'
    )
    if [ "$1" ]; then
        echo "$data" | jq -r ".$1"
    else
        echo "$data"
    fi
}

case $1 in
    sum) query_sum "${@:2}" ;;
    tip) query_tip "${@:2}" ;;
    params) query_params "${@:2}" ;;
    state) query_state "${@:2}" ;;
    metrics) query_metrics "${@:2}" ;;
    config) query_config "${@:2}" ;;
    key) query_key "${@:2}" ;;
    keys) query_keys "${@:2}" ;;
    kes) query_kes ;;
    kes_period) query_kes_period ;;
    uxto) query_uxto "${@:2}" ;;
    leader) query_leader "${@:2}" ;;
    rewards) query_rewards "${@:2}" ;;
    help) help "${2:-"--help"}" ;;
    *) help "${1:-"--help"}" ;;
esac
