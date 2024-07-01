#!/bin/bash

source "$(dirname "$0")/../common/common.sh"
help 15 1 ${@} || exit
source "$(dirname "$0")/../../networks/${1}/env"

stakeAddressDeposit=$(cat $NETWORK_PATH/params.json | jq -r '.stakeAddressDeposit')
addrFrom=$(cat "${PAYMENT_ADDR}")
outputPath=${NODE_HOME}/temp
currentSlot=$(cardano-cli query tip $NETWORK_ARG --socket-path $NETWORK_SOCKET_PATH | jq -r '.slot')

print 'TX' 'list UXTOs:'
cardano-cli query utxo --socket-path $NETWORK_SOCKET_PATH --address $addrFrom $NETWORK_ARG > $outputPath/fullUtxo.out
tail -n +3 $outputPath/fullUtxo.out | sort -k3 -nr > $outputPath/balance.out
cat $outputPath/balance.out
txIn=""
totalBalance=0
while read -r utxo; do
    type=$(awk '{ print $6 }' <<< "${utxo}")
    if [[ ${type} == 'TxOutDatumNone' ]]
    then
        inAddr=$(awk '{ print $1 }' <<< "${utxo}")
        idx=$(awk '{ print $2 }' <<< "${utxo}")
        utxoBalance=$(awk '{ print $3 }' <<< "${utxo}")
        totalBalance=$((${totalBalance}+${utxoBalance}))
        txIn="${txIn} --tx-in ${inAddr}#${idx}"
    fi
done < $outputPath/balance.out
txcnt=$(cat $outputPath/balance.out | wc -l)

cardano-cli transaction build-raw \
    ${txIn} \
    --tx-out ${addrFrom}+0 \
    --invalid-hereafter $(( ${currentSlot} + 10000)) \
    --fee 0 \
    --out-file $outputPath/tx.tmp \
    --certificate $STAKE_CERT
    
fee=$(cardano-cli transaction calculate-min-fee \
    --tx-body-file $outputPath/tx.tmp \
    --tx-in-count ${txcnt} \
    --tx-out-count 1 \
    $NETWORK_ARG \
    --witness-count 2 \
    --byron-witness-count 0 \
    --protocol-params-file $NETWORK_PATH/params.json | awk '{ print $1 }')

txOut=$((${totalBalance}-${stakeAddressDeposit}-${fee}))

cardano-cli transaction build-raw \
    ${txIn} \
    --tx-out ${addrFrom}+${txOut} \
    --invalid-hereafter $(( ${currentSlot} + 10000)) \
    --fee ${fee} \
    --certificate-file $STAKE_CERT \
    --out-file $outputPath/tx.raw

rm $outputPath/fullUtxo.out
rm $outputPath/balance.out
rm $outputPath/tx.tmp

print 'TX' "Stake address deposit: ${stakeAddressDeposit}"
print 'TX' "Current slot: ${currentSlot}"
print 'TX' "Available balance: ${totalBalance}"
print 'TX' "Num of UTXOs: ${txCount}"
print 'TX' "Fee: ${fee}"
print 'TX' "Change output: ${txOut}"
print 'TX' "File output: ${outputPath}/tx.raw" $green
