#!/bin/bash
# Usage: pool.sh [
#   generate_node_keys |
#   generate_kes_keys |
#   generate_vrf_keys |
#   generate_node_op_cert [kesPeriod] |
#   generate_pool_reg_cert [pledge] [cost] [margin] [relayAddress] [relayPort] [metadataUrl] [metadataHash] |
#   generate_pool_dreg_cert [epoch] |
#   generate_metadata_hash |
#   get_pool_id [?format] |
#   get_stats |
#   rotate_kes [startPeriod] |
#   help [?-h]
# ]
#
# Info:
#
#   - generate_node_keys) Generate node key pair.
#   - generate_kes_keys) Generate node KES key pair.
#   - generate_vrf_keys) Generate node VRF key pair and sets permissions.
#   - generate_node_op_cert) Generate node operational certificate. Requires the kesPeriod parameter.
#   - generate_pool_reg_cert) Generate pool registration certificate. Requires all params to generate the certificate.
#   - generate_pool_dreg_cert) Generate pool registration certificate.
#   - generate_metadata_hash) Generate pools metadata hash from the metadata.json file.
#   - get_pool_id) Output the pool ID to $POOL_ID and display it on screen. Optionally pass in the format, defaults to hex.
#   - get_stats) Retrieve pool stats from js.cexplorer.io.
#   - rotate_kes) Rotate the pool KES keys. Requires KES startPeriod as the first parameter.
#   - help) View this files help. Default value if no option is passed.

source "$(dirname "$0")/../env"
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
  if [ -f $VRF_KEY ]; then
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
  if [ -f $POOL_CERT ]; then
    confirm "Certificate already exist! 'yes' to overwrite, 'no' to cancel"
  fi
  pledge="${1}"
  cost="${2}"
  margin="${3}"
  relayAddr="${4}"
  relayPort="${5}"
  metaUrl="${6}"
  metaHash="${7:-$(cat metadata/metadataHash.txt)}"
  $CNCLI conway stake-pool registration-certificate \
    --cold-verification-key-file $NODE_VKEY \
    --vrf-verification-key-file $VRF_VKEY \
    --pool-pledge $pledge \
    --pool-cost $cost \
    --pool-margin $margin \
    --pool-reward-account-verification-key-file $STAKE_VKEY \
    --pool-owner-stake-verification-key-file $STAKE_VKEY \
    $NETWORK_ARG \
    --single-host-pool-relay $relayAddr \
    --pool-relay-port $relayPort \
    --metadata-url $metaUrl \
    --metadata-hash $metaHash \
    --out-file $POOL_CERT
  print 'POOL' "Node registration certificate created at $POOL_CERT" $green
}

pool_generate_pool_dreg_cert() {
  $CNCLI conway stake-pool deregistration-certificate \
    --cold-verification-key-file $NODE_VKEY \
    --epoch $1 \
    --out-file $POOL_DREG_CERT
}

pool_generate_pool_meta_hash() {
  exit_if_not_producer
  inputFile="metadata/metadata.json"
  outputFile="metadata/metadataHash.txt"
  if [ -f $inputFile ]; then
    $CNCLI conway stake-pool metadata-hash \
      --pool-metadata-file "${inputFile}" > "${outputFile}"
    print 'POOL' "Node metadata hash created at $outputFile" $green
  else
    print 'POOL' "Node metadata file not found $inputFile" $red
  fi
}

pool_get_pool_id() {
  exit_if_not_cold
  format="${1:-hex}"
  $CNCLI conway stake-pool id --cold-verification-key-file $NODE_VKEY --output-format $format > $POOL_ID
  echo "$(cat $POOL_ID)"
}

pool_get_stats() {
  curl -X GET https://api.cardanoscan.io/api/v1/pool/stats?poolId=$(cat $POOL_ID) \
    -H "apiKey: $NODE_CARDANOSCAN_API" 2>/dev/null \
    | jq 'del(.poolId)' \
    | tr -d \"{},: \
    | awk NF \
    | sed -e 's/^[ \t]*/data_/' \
    > $NETWORK_PATH/stats/data-pool.prom

  chmod +r $NETWORK_PATH/stats/data-pool.prom
  sed 's/ /: /g' $(cat $NETWORK_PATH/stats/data-pool.prom)
}

pool_rotate_kes() {
  exit_if_not_cold
  startPeriod="${1}"

  if [ $startPeriod ]; then
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
    return 0
  fi

  print 'KES' "Please provide a KES startPeriod" $red
  exit 1
}

case $1 in
  generate_node_keys) pool_generate_node_keys ;;
  generate_kes_keys) pool_generate_node_kes_keys ;;
  generate_vrf_keys) pool_generate_node_vrf_keys ;;
  generate_node_op_cert) pool_generate_node_op_cert "${@:2}" ;;
  generate_pool_reg_cert) pool_generate_pool_reg_cert "${@:2}" ;;
  generate_pool_dreg_cert) pool_generate_pool_dreg_cert "${@:2}" ;;
  generate_pool_meta_hash) pool_generate_pool_meta_hash ;;
  get_pool_id) pool_get_pool_id "${@:2}" ;;
  get_stats) pool_get_stats ;;
  rotate_kes) pool_rotate_kes "${@:2}" ;;
  help) help "${2:-"--help"}" ;;
  *) help "${1:-"--help"}" ;;
esac
