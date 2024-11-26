#!/bin/bash
# Usage: scripts/pool/buildpoolcert.sh <stakePoolDeposit>
#
# Info:
#
#   - Build pool certificate raw transaction
#   - Network param file must exist by calling scripts/query/params.sh

source "$(dirname "$0")/../../env"
source "$(dirname "$0")/../common.sh"
paymentAddr=$(cat "${PAYMENT_ADDR}")
outputPath=$NETWORK_PATH/temp
currentSlot=$($CNCLI conway query tip $NETWORK_ARG --socket-path $NETWORK_SOCKET_PATH | jq -r '.slot')
stakePoolDeposit=${1:-$(cat $NETWORK_PATH/params.json | jq -r '.stakePoolDeposit')}
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
    --tx-out ${paymentAddr}+$(( ${totalBalance} - ${stakePoolDeposit} ))  \
    --invalid-hereafter $(( ${currentSlot} + 10000)) \
    --fee 200000 \
    --certificate-file $POOL_CERT \
    --certificate-file $DELE_CERT \
    --out-file $outputPath/tx.tmp
    
fee=$($CNCLI conway transaction calculate-min-fee \
    --tx-body-file $outputPath/tx.tmp \
    --tx-in-count ${txCount} \
    --tx-out-count 1 \
    $NETWORK_ARG \
    --witness-count 3 \
    --byron-witness-count 0 \
    --protocol-params-file $NETWORK_PATH/params.json | awk '{ print $1 }')

txOut=$((${totalBalance}-${stakePoolDeposit}-${fee}))

$CNCLI conway transaction build-raw \
    ${txIn} \
    --tx-out ${paymentAddr}+${txOut} \
    --invalid-hereafter $(( ${currentSlot} + 10000)) \
    --fee ${fee} \
    --certificate-file $POOL_CERT \
    --certificate-file $DELE_CERT \
    --out-file $outputPath/tx.raw
    
rm $outputPath/fullUtxo.out
rm $outputPath/balance.out
rm $outputPath/tx.tmp

echo Current slot: $currentSlot
echo Available balance: ${totalBalance}
echo Num of UTXOs: ${txCount}
echo Fee: ${fee}
echo Change output: ${txOut}
echo File output: ${outputPath}/tx.raw

print 'TX' "Stake pool deposit: ${stakePoolDeposit}"
print 'TX' "Available balance: ${totalBalance}"
print 'TX' "Num of UTXOs: ${txCount}"
print 'TX' "Fee: ${fee}"
print 'TX' "Change output: ${txOut}"
print 'TX' "File output: ${outputPath}/tx.raw" $green
