#!/bin/bash

# Define global variables

source_from="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$source_from/../env"

NETWORK_ARG=
case $NODE_NETWORK in
    "mainnet") NETWORK_ARG="--mainnet" ;;
    "preprod") NETWORK_ARG="--testnet-magic 1" ;;
    "preview") NETWORK_ARG="--testnet-magic 2" ;;
    "sanchonet") NETWORK_ARG="--testnet-magic 4" ;;
esac

CONFIG_PATH=
case $NODE_TYPE in
    "relay") CONFIG_PATH=$NETWORK_PATH/config.json ;;
    "producer") CONFIG_PATH=$NETWORK_PATH/config-bp.json ;;
esac

CONFIG_DOWNLOADS=(
    "config.json"
    "config-bp.json"
    "db-sync-config.json"
    "submit-api-config.json"
    "topology.json"
    "topology-genesis-mode.json"
    "peer-snapshot.json"
    "byron-genesis.json"
    "shelley-genesis.json"
    "alonzo-genesis.json"
    "conway-genesis.json"
    "guardrails-script.plutus"
    "topology-non-bootstrap-peers.json"
    "checkpoints.json"
)

GUILD_SCRIPT_DOWNLOADS=(
    "gLiveView.sh"
    "env"
)

MITHRIL_AGGREGATOR_ENDPOINT=
case $NODE_NETWORK in
    "mainnet") MITHRIL_AGGREGATOR_ENDPOINT=https://aggregator.release-mainnet.api.mithril.network/aggregator ;;
    "preprod") MITHRIL_AGGREGATOR_ENDPOINT=https://aggregator.release-preprod.api.mithril.network/aggregator ;;
    "preview") MITHRIL_AGGREGATOR_ENDPOINT=https://aggregator.pre-release-preview.api.mithril.network/aggregator ;;
esac

MITHRIL_AGGREGATOR_PARAMS=
case $NODE_NETWORK in
    "mainnet") MITHRIL_AGGREGATOR_PARAMS=$(jq -nc --arg address $(wget -q -O - https://raw.githubusercontent.com/input-output-hk/mithril/main/mithril-infra/configuration/release-mainnet/era.addr) --arg verification_key $(wget -q -O - https://raw.githubusercontent.com/input-output-hk/mithril/main/mithril-infra/configuration/release-mainnet/era.vkey) '{"address": $address, "verification_key": $verification_key}') ;;
    "preprod") MITHRIL_AGGREGATOR_PARAMS=$(jq -nc --arg address $(wget -q -O - https://raw.githubusercontent.com/input-output-hk/mithril/main/mithril-infra/configuration/release-preprod/era.addr) --arg verification_key $(wget -q -O - https://raw.githubusercontent.com/input-output-hk/mithril/main/mithril-infra/configuration/release-preprod/era.vkey) '{"address": $address, "verification_key": $verification_key}') ;;
    "preview") MITHRIL_AGGREGATOR_PARAMS=$(jq -nc --arg address $(wget -q -O - https://raw.githubusercontent.com/input-output-hk/mithril/main/mithril-infra/configuration/pre-release-preview/era.addr) --arg verification_key $(wget -q -O - https://raw.githubusercontent.com/input-output-hk/mithril/main/mithril-infra/configuration/pre-release-preview/era.vkey) '{"address": $address, "verification_key": $verification_key}') ;;
esac

GOV_ACTION_TYPES=(
    "motion_no_confidence"
    "committee_update"
    "constitution_update"
    "hard_fork_initiation"
    "parameter_change"
    "treasury_withdrawal"
    "info"
)

# Overrides for sancho

if [ "$NODE_NETWORK" == "sanchonet" ]; then
    CONFIG_REMOTE="https://raw.githubusercontent.com/Hornan7/SanchoNet-Tutorials/refs/heads/main/genesis/"
    CONFIG_DOWNLOADS=(
        "config.json"
        "topology.json"
        "byron-genesis.json"
        "shelley-genesis.json"
        "alonzo-genesis.json"
        "conway-genesis.json"
        "guardrails-script.plutus"
    )
fi

# Define global colours

blue='\033[0;34m'
orange='\033[0;33m'
green='\033[0;32m'
red='\033[0;31m'
nc='\033[0m'

# Define global functions

help() {
    echo -e $orange
    sed -ne '/^#/!q;s/^#$/# /;/^# /s/^# //p' <"$0" |
        awk -v f="${1#-h}" '!f && /^Usage:/ || u { u=!/^\s*$/; if (!u) exit } u || f'
    echo -e $nc
    exit 1
}

print() {
    label=${1:-'LABEL'}
    message=${2:-'Message'}
    color=${3:-$orange}
    echo -e "$color[$label] $message$nc"
    if [ -f "$NETWORK_PATH/logs/script.log" ]; then
        echo -e "$color[$label] $message$nc" >>$NETWORK_PATH/logs/script.log
    fi
}

confirm() {
    read -p "$1 ([y]es or [N]o): "
    case $(echo $REPLY | tr '[A-Z]' '[a-z]') in
        y | yes) echo "yes" ;;
        *) exit 1 ;;
    esac
}

platform() {
    OS=$(uname)
    if [[ "$OS" == "Linux" ]]; then
        echo "linux"
    elif [[ "$OS" == "Darwin" ]]; then
        echo "macos"
    elif [[ "$OS" == "MINGW"* || "$OS" == "CYGWIN"* ]]; then
        echo "windows"
    else
        echo "unknown"
    fi
}

platform_arm() {
    ARCH=$(uname -m)
    if [[ "$ARCH" == "arm"* || "$ARCH" == "aarch64" ]]; then
        echo "arm"
    fi
}

platform_ctl() {
    if [ -f /.dockerenv ]; then
        return 1
    else
        return 0
    fi
}

get_param() {
    echo "$1" | grep "^$2" | awk '{for(i=2; i<=NF; i++) printf "%s ", $i; print ""}'
}

get_option() {
    local option_name="$1"
    local option_value=""
    shift
    while [[ $# -gt 1 ]]; do
        case "$1" in
            "$option_name")
                option_value="$option_value $1 $2"
                shift 2 # move past the option and its value
                ;;
            *)
                shift # unknown option
                ;;
        esac
    done
    echo "$option_value"
}

update_or_append() {
    file=${1}
    check=${2}
    line=${3}
    if grep -q "^$check" "$file"; then
        sudo sed -i "s|^$check.*|$line|" "$file"
    else
        echo "$line" | sudo tee -a $file >/dev/null
    fi
}

exit_if_file_missing() {
    if [ ! -f $1 ]; then
        print 'ERROR' "File $1 does not exist" $red
        exit 1
    fi
}

exit_if_cold() {
    if [[ $NODE_TYPE == 'cold' && $NODE_NETWORK == 'mainnet' ]]; then
        print "ERROR" "this command can not be run on a cold device" $red
        exit 1
    fi
}

exit_if_not_cold() {
    if [[ $NODE_TYPE != 'cold' && $NODE_NETWORK == 'mainnet' ]]; then
        print "ERROR" "this command can only be run on a cold device" $red
        exit 1
    fi
}

exit_if_not_producer() {
    if [[ $NODE_TYPE != 'producer' && $NODE_NETWORK == 'mainnet' ]]; then
        print "ERROR" "this command can only be run on a producer device" $red
        exit 1
    fi
}

exit_if_not_relay() {
    if [[ $NODE_TYPE != 'relay' && $NODE_NETWORK == 'mainnet' ]]; then
        print "ERROR" "this command can only be run on a relay device" $red
        exit 1
    fi
}
