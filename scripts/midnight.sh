#!/bin/bash
# Usage: midnight.sh [
#   query |
#   help [?-h]
# ]
#
# Info:
#
#   - query) Query the api via CURL with the passed options and return the pain response or an [ERROR]: `query "sidechain_getStatus" "[]" | jq`
#   - help) View this files help. Default value if no option is passed.

source "$(dirname "$0")/../env"
source "$(dirname "$0")/common.sh"

MIDNIGHT_API_HOST="127.0.0.1"
MIDNIGHT_API_PORT="9944"
MIDNIGHT_API_URL="http://${MIDNIGHT_API_HOST}:${MIDNIGHT_API_PORT}"
MIDNIGHT_API_CURL_OPTS=(
  -s          # silent
  -S          # show errors
  --fail      # fail on HTTP error
  -L          # follow redirects
)

midnight_query_rpc() {
    exit_if_empty "${1}" "1 method"
    exit_if_empty "${2}" "2 params"
    local method="$1"
    local params="$2"
    local id="${3:-1}"
    local payload
    payload=$(cat <<EOF
{
  "jsonrpc": "2.0",
  "method": "${method}",
  "params": ${params},
  "id": ${id}
}
EOF
)
    # Perform the request
    local response
    if ! response=$(curl "${MIDNIGHT_API_CURL_OPTS[@]}" -X POST -H "Content-Type: application/json" \
        -d "${payload}" "${MIDNIGHT_API_URL}" 2>/dev/null); then
        print_json_error "Failed to reach API at ${MIDNIGHT_API_URL}"
        return 1
    fi

    # Detect JSON-RPC errors inside the response
    if echo "$response" | jq -e '.error' >/dev/null 2>&1; then
        echo "$response"
        return 1
    fi

    echo "$response"
}

midnight_query_status() {
    echo $(midnight_query_rpc "sidechain_getStatus" "[]") | jq
}

midnight_query_validators() {
    local epoch=${1}

    # If no epoch passed, fetch it from status
    if [[ -z "$epoch" ]]; then
        epoch=$(midnight_query_status | jq -r '.result.mainchain.epoch')
        if [[ -z "$epoch" || "$epoch" == "null" ]]; then
            print_json_error "Unable to determine current epoch"
            return 1
        fi
    fi

    # Call RPC with epoch as JSON array
    midnight_query_rpc "sidechain_getAriadneParameters" "[$epoch]" | jq
}

midnight_query_validate() {
    exit_if_empty "$1" "1 type"
    exit_if_empty "$2" "2 author key"
    local type="$1"
    local key="$2"
    echo $(midnight_query_rpc "author_hasKey" "[\"$key\",\"$type\"]") | jq
}

midnight_query_peers() {
    echo $(midnight_query_rpc "system_peers" "[]") | jq
}

case $1 in
    query) midnight_query_rpc "${@:2}" ;;
    status) midnight_query_status ;;
    validators) midnight_query_validators "${@:2}" ;;
    validate) midnight_query_validate "${@:2}" ;;
    peers) midnight_query_peers ;;
    help) help "${2:-"--help"}" ;;
    *) help "${1:-"--help"}" ;;
esac
