#!/bin/bash
# Usage: pool.sh [
#   tip [?name] |
#   params [?name] |
#   config [name] |
#   key [name] |
#   kes_period |
#   uxto [?address] |
#   leader [?period] |
#   help [?-h]
# ]
#
# Info:
#
#   - tip) Query the blockchain tip. Optionally pass a param name to view only this value.
#   - params) Query the blockchain protocol params and save these to $NETWORK_PATH/params.json. Optionally pass a param name to view only this value.
#   - config) Echo the contents of any config file located in $NETWORK_PATH. Pass the file name you wish to read.
#   - key) Echo the contents of any fle located in $NETWORK_PATH/keys. Pass the file name you wish to read.
#   - kes_period) Query the kes period params. Useful when generating pool certificates.
#   - kes_state) Query the current $NODE_CERT on chain kes state.
#   - uxto) Query the uxto for an address. Defaults to $PAYMENT_ADDR if non is passed.
#   - leader) Run the pool leader slot query. Pass the period to choose which epoch to query ['next' | 'current' | 'previous' ].
#   - help) View this files help. Default value if no option is passed.

source "$(dirname "$0")/../env"
source "$(dirname "$0")/common.sh"

query_tip() {
  exit_if_cold
  field=${1}
  if [ "$field" ]; then
    value=$($CNCLI conway query tip $NETWORK_ARG --socket-path $NETWORK_SOCKET_PATH | jq -r ".$field")
    print 'QUERY' "$field: ${value}"
  else
    print "QUERY" "\n$($CNCLI conway query tip $NETWORK_ARG --socket-path $NETWORK_SOCKET_PATH)"
  fi
}

query_params() {
  exit_if_cold
  field=${1}
  $CNCLI conway query protocol-parameters \
      $NETWORK_ARG \
      --socket-path $NETWORK_SOCKET_PATH \
      --out-file $NETWORK_PATH/params.json
  print "QUERY" "Output saved to $NETWORK_PATH/params.json" $green
  if [ "$field" ]; then
    value=$(cat $NETWORK_PATH/params.json | jq -r ".$field")
    print 'QUERY' "$field: ${value}"
  else
    print 'QUERY' "\n$(cat $NETWORK_PATH/params.json)"
  fi
}

query_config() {
  if [ -f $NETWORK_PATH/$1 ]; then
    print 'QUERY' "\n$(cat $NETWORK_PATH/$1)"
    return 0
  fi
  print 'QUERY' "File $1 does not exist" $red
}

query_key() {
  if [ -f $NETWORK_PATH/keys/$1 ]; then
    print 'QUERY' "\n$(cat $NETWORK_PATH/keys/$1)"
    return 0
  fi
  print 'QUERY' "File $1 does not exist" $red
}

query_kes_period() {
  exit_if_cold
  slotsPerKESPeriod=$(cat $NETWORK_PATH/shelley-genesis.json | jq -r '.slotsPerKESPeriod')
  slotNo=$($CNCLI conway query tip $NETWORK_ARG --socket-path $NETWORK_SOCKET_PATH | jq -r '.slot')
  kesPeriod=$((${slotNo} / ${slotsPerKESPeriod}))
  print 'QUERY' "slotsPerKESPeriod: ${slotsPerKESPeriod}"
  print 'QUERY' "currentSlot: ${slotNo}"
  print 'QUERY' "kesPeriod: ${kesPeriod}"
}

query_kes_state() {
  exit_if_not_producer
  output=$($CNCLI conway query kes-period-info $NETWORK_ARG \
    --socket-path $NETWORK_SOCKET_PATH \
    --op-cert-file $NODE_CERT)
  print 'QUERY' "\n${output}"
}

query_uxto() {
  exit_if_cold
  address=${1:-"$PAYMENT_ADDR"}
  content=$($CNCLI conway query utxo --address $(cat $address) $NETWORK_ARG --socket-path $NETWORK_SOCKET_PATH)
  print 'QUERY' "\n$content"
}

query_leader() {
  period=${1:-"next"}
  targetEpoch=$(query_tip epoch)
  if [ $period != 'next' ] | [ $period != 'previous' ] | [ $period != 'current' ]; then
      print 'ERROR' "Leadership schedule incorrect period value: $period"
      exit 0
  fi
  if [ $period == 'next' ]; then targetEpoch=$targetEpoch + 1; fi
  if [ $period == 'previous' ]; then targetEpoch=$targetEpoch - 1; fi
  outputPath=$NETWORK_PATH/logs/leader/$targetEpoch # filename path excludes extension

  print 'QUERY' "Leadership schedule starting"
  cardano-cli query leadership-schedule \
    --mainnet \
    --stake-pool-id $POOL_ID \
    --vrf-signing-key-file $NODE_HOME/vrf.skey \
    --genesis $NODE_HOME/shelley-genesis.json \
    --$period > $outputPath.txt

  if [ -f $outputPath.txt ]; then
    echo "$(tail -n +3 $outputPath.txt)" > $outputPath.txt
    awk '{print $2,$3","$1","NR}' $outputPath.txt > $outputPath.csv
    sed -i '1 i\Time,Slot,No' $outputPath.csv
    rm $outputPath.txt
    print 'QUERY' "Leader slot results:\n $(cat $outputPath.csv)"
  else
    print 'ERROR' "Leadership schedule failed"
    exit 0
  fi
}

case $1 in
  tip) query_tip "${@:2}" ;;
  params) query_params "${@:2}" ;;
  config) query_config "${@:2}" ;;
  key) query_key "${@:2}" ;;
  kes_period) query_kes_period ;;
  kes_state) query_kes_state ;;
  uxto) query_uxto "${@:2}" ;;
  leader) query_leader "${@:2}" ;;
  help) help "${2:-"--help"}" ;;
  *) help "${1:-"--help"}" ;;
esac
