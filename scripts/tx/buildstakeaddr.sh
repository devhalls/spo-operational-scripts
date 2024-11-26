#!/bin/bash
# Usage: scripts/tx/buildstakeaddr.sh
#
# Info:
#
#   - Build tx to register your stake address
#   - Network param file must exist by calling scripts/query/params.sh

source "$(dirname "$0")/../../env"
source "$(dirname "$0")/../common.sh"
paymentAddr=$(cat "${PAYMENT_ADDR}")
outputPath=$NETWORK_PATH/temp
currentSlot=$($CNCLI conway query tip $NETWORK_ARG --socket-path $NETWORK_SOCKET_PATH | jq -r '.slot')
stakeAddressDeposit=$(cat $NETWORK_PATH/params.json | jq -r '.stakeAddressDeposit')
txIn=""
totalBalance=0
txCount=0

$CNCLI conway query utxo --socket-path $NETWORK_SOCKET_PATH --address $paymentAddr $NETWORK_ARG > $outputPath/fullUtxo.out
tail -n +3 $outputPath/fullUtxo.out | sort -k3 -nr > $outputPath/balance.out
cat $outputPath/balance.out
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
txCount=$(cat $outputPath/balance.out | wc -l)

$CNCLI conway transaction build-raw \
    ${txIn} \
    --tx-out ${paymentAddr}+$(( ${totalBalance} - ${stakeAddressDeposit} )) \
    --invalid-hereafter $(( ${currentSlot} + 10000 )) \
    --fee 2000000 \
    --out-file $outputPath/tx.tmp \
    --certificate $STAKE_CERT
    
fee=$($CNCLI conway transaction calculate-min-fee \
    --tx-body-file $outputPath/tx.tmp \
    --tx-in-count ${txCount} \
    --tx-out-count 1 \
    $NETWORK_ARG \
    --witness-count 2 \
    --byron-witness-count 0 \
    --protocol-params-file $NETWORK_PATH/params.json | awk '{ print $1 }')

txOut=$((${totalBalance}-${stakeAddressDeposit}-${fee}))

$CNCLI conway transaction build-raw \
    ${txIn} \
    --tx-out ${paymentAddr}+${txOut} \
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
