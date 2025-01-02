#!/bin/bash
# Usage: pool.sh [
#   tip [?name] |
#   params [?name] |
#   metrics [?name] |
#   config [name] |
#   key [name] |
#   kes |
#   kes_period |
#   uxto [?address] |
#   leader [?period] |
#   rewards [?name] |
#   help [?-h]
# ]
#
# Info:
#
#   - tip) Query the blockchain tip. Optionally pass a param name to view only this value.
#   - params) Query the blockchain protocol parameters and saves these to $NETWORK_PATH/params.json. Optionally pass a param name to view only this value.
#   - metrics) Query the prometheus metrics. Optionally pass a param name to view only this value.
#   - config) Echo the contents of any config file located in $NETWORK_PATH. Pass the file name you wish to read.
#   - key) Echo the contents of any fle located in $NETWORK_PATH/keys. Pass the file name you wish to read.
#   - kes) Query the current $NODE_CERT on chain kes state.
#   - kes_period) Query the kes period params. Useful when generating pool certificates.
#   - uxto) Query the uxto for an address. Defaults to $PAYMENT_ADDR if non is passed.
#   - leader) Run the pool leader slot query. Pass the period to choose which epoch to query ['next' | 'current' | 'previous' ].
#   - rewards) Query stake address info. Optionally pass a param name to view only this value.
#   - help) View this files help. Default value if no option is passed.

source "$(dirname "$0")/../env"
source "$(dirname "$0")/common.sh"

query_tip() {
  exit_if_cold
  if [ "$1" ]; then
    $CNCLI conway query tip $NETWORK_ARG --socket-path $NETWORK_SOCKET_PATH | jq -r ".$1"
  else
    $CNCLI conway query tip $NETWORK_ARG --socket-path $NETWORK_SOCKET_PATH; echo ''
  fi
}

query_params() {
  exit_if_cold
  $CNCLI conway query protocol-parameters $NETWORK_ARG --socket-path $NETWORK_SOCKET_PATH \
    --out-file $NETWORK_PATH/params.json
  if [ "$1" ]; then
    cat $NETWORK_PATH/params.json | jq -r ".$1"
  else
    cat $NETWORK_PATH/params.json; echo ''
  fi
}

query_metrics() {
  exit_if_cold
  if [ "$1" ]; then
    curl -s 127.0.0.1:12798/metrics | grep "$1"
  else
    curl -s 127.0.0.1:12798/metrics
  fi
}

query_config() {
  exit_if_file_missing $NETWORK_PATH/$1
  cat $NETWORK_PATH/$1; echo ''
}

query_key() {
  exit_if_file_missing $NETWORK_PATH/keys/$1
  cat $NETWORK_PATH/keys/$1; echo ''
}

query_kes() {
  exit_if_not_producer
  $CNCLI conway query kes-period-info $NETWORK_ARG --socket-path $NETWORK_SOCKET_PATH \
    --op-cert-file $NODE_CERT
}

query_kes_period() {
  exit_if_cold
  slotsPerKESPeriod=$(cat $NETWORK_PATH/shelley-genesis.json | jq -r '.slotsPerKESPeriod')
  slotNo=$(query_tip slot)
  kesPeriod=$(($slotNo / $slotsPerKESPeriod))
  echo "slotsPerKESPeriod $slotsPerKESPeriod"
  echo "currentSlot $slotNo"
  echo "kesPeriod $kesPeriod"
}

query_uxto() {
  exit_if_cold
  $CNCLI conway query utxo $NETWORK_ARG --socket-path $NETWORK_SOCKET_PATH \
    --address ${1:-"$(cat $PAYMENT_ADDR)"}
}

query_leader() {
  # Set the query period and targetEpoch
  period="--${1:-"next"}"
  targetEpoch=$(query_tip epoch)
  if [[ $period != '--next' && $period != '--current' ]]; then
      print 'ERROR' "Leadership schedule incorrect period value: $period"
      exit 0
  fi
  if [ $period == '--next' ]; then targetEpoch=$(($targetEpoch+1)); fi
  if [ $period == '--previous' ]; then targetEpoch=$(($targetEpoch-1)); fi

  # Set file paths and get the poolId
  outputPath=$NETWORK_PATH/logs
  tempFilePath=$outputPath/$targetEpoch.txt
  csvFile=$outputPath/slots.csv
  grafanaLocation=/usr/share/grafana/slots.csv
  poolId=$(bash "$(dirname "$0")/pool.sh" get_pool_id bech32)

  # Run the leadership-schedule query
  print 'QUERY' "Leadership schedule starting, please wait..."
  cardano-cli query leadership-schedule $NETWORK_ARG --socket-path $NETWORK_SOCKET_PATH \
    --genesis $NETWORK_PATH/shelley-genesis.json \
    --stake-pool-id $poolId \
    --vrf-signing-key-file $VRF_KEY \
    $period > $tempFilePath
  if [ $? -ne 0 ]; then
    print 'ERROR' "Leadership schedule failed to run" $red
    exit 0
  fi

  # Create the CSV file if it does not exist
  if [ ! -f $csvFile ]; then
    echo 'Time,Slot,No,Epoch' > $csvFile 2>/dev/null
  fi

  # Process the output file adding values to $csvFile, echo the result, and copy to grafana folder
  if [ -f $tempFilePath ]; then
    echo "$(tail -n +3 $tempFilePath)" > $tempFilePath
    sed -i "s/\$/ $targetEpoch/" $tempFilePath
    content=$(awk '{print $2,$3","$1","NR","$5}' $tempFilePath)
    grep -qxF "$content" $csvFile || echo "$content" >> $csvFile
    echo "$content"
    rm $tempFilePath
    sudo cp $csvFile $grafanaLocation
  else
    print 'ERROR' "Leadership schedule failed to run" $red
    exit 0
  fi
}

query_rewards() {
  data=$(
    $CNCLI conway query stake-address-info $NETWORK_ARG --socket-path $NETWORK_SOCKET_PATH \
      --address $(< $STAKE_ADDR) | jq '.[0]'
  )
  if [ "$1" ]; then
    echo "$data" | jq -r ".$1"
  else
    echo "$data"
  fi
}

case $1 in
  tip) query_tip "${@:2}" ;;
  params) query_params "${@:2}" ;;
  metrics) query_metrics "${@:2}" ;;
  config) query_config "${@:2}" ;;
  key) query_key "${@:2}" ;;
  kes) query_kes ;;
  kes_period) query_kes_period ;;
  uxto) query_uxto "${@:2}" ;;
  leader) query_leader "${@:2}" ;;
  rewards) query_rewards "${@:2}" ;;
  help) help "${2:-"--help"}" ;;
  *) help "${1:-"--help"}" ;;
esac
