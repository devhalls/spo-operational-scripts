#!/bin/bash

source "$(dirname "$0")/../../networks/${1}/env"
source "$(dirname "$0")/../common/common.sh"
help 14 1 ${@} || exit

# Set local variables
lovelace="${2}"
addrTo="${3}"
addrFrom=$(cat "${PAYMENT_ADDR}")
outputPath=${NODE_HOME}/temp
currentSlot=$(cardano-cli query tip $NETWORK_ARG --socket-path $NETWORK_SOCKET_PATH | jq -r '.slot')

# Get the UXTOs and calculate the tx inputs
print 'TX' 'list UXTOs:'
cardano-cli query utxo --socket-path $NETWORK_SOCKET_PATH --address $addrFrom $NETWORK_ARG > $outputPath/fullUtxo.out
tail -n +3 $outputPath/fullUtxo.out | sort -k3 -nr > $outputPath/balance.out
cat $outputPath/balance.out
txIn=""
totalBalance=0
while read -r utxo; do
    inAddr=$(awk '{ print $1 }' <<< "${utxo}")
    idx=$(awk '{ print $2 }' <<< "${utxo}")
    utxoBalance=$(awk '{ print $3 }' <<< "${utxo}")
    totalBalance=$((${totalBalance}+${utxoBalance}))
    txIn="${txIn} --tx-in ${inAddr}#${idx}"
done < $outputPath/balance.out
txCount=$(cat $outputPath/balance.out | wc -l)

# Build a tmp tx and calculate the fee
cardano-cli transaction build-raw \
    ${txIn} \
    --tx-out ${addrFrom}+0 \
    --tx-out ${addrTo}+0 \
    --invalid-hereafter $(( ${currentSlot} + 10000)) \
    --fee 0 \
    --out-file $outputPath/tx.tmp

fee=$(cardano-cli transaction calculate-min-fee \
    --tx-body-file $outputPath/tx.tmp \
    --tx-in-count ${txCount} \
    --tx-out-count 2 \
    $NETWORK_ARG \
    --witness-count 1 \
    --byron-witness-count 0 \
    --protocol-params-file $NETWORK_PATH/params.json | awk '{ print $1 }')

txOut=$((${totalBalance}-${lovelace}-${fee}))

# Build the final tx ready to be signed
cardano-cli transaction build-raw \
    ${txIn} \
    --tx-out ${addrFrom}+${txOut} \
    --tx-out ${addrTo}+${lovelace} \
    --invalid-hereafter $(( ${currentSlot} + 10000)) \
    --fee ${fee} \
    --out-file $outputPath/tx.raw

# Clean up
rm $outputPath/fullUtxo.out
rm $outputPath/balance.out
rm $outputPath/tx.tmp

print 'TX' "Amount to send: ${lovelace}"
print 'TX' "Current slot: ${currentSlot}"
print 'TX' "Available balance: ${totalBalance}"
print 'TX' "Num of UTXOs: ${txCount}"
print 'TX' "Fee: ${fee}"
print 'TX' "Change output: ${txOut}"
print 'TX' "File output: ${outputPath}/tx.raw" $green
