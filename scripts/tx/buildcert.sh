#!/bin/bash

# Info : Builds a raw transaction file top submit pool certificate.
#      : Expects env with set varibles.
# Use  : cd $NODE_HOME
#      : scripts/tx/buildcert.sh <sanchonet | preview | preprod | mainnet>

source "$(dirname "$0")/../../networks/${3:-"preview"}/env"

paymentAddr=$(cat "${PAYMENT_ADDR}")
outputPath=${NODE_HOME}/temp
currentSlot=$(cardano-cli query tip $NETWORK_ARG | jq -r '.slot')

echo list UXTO: 
cardano-cli query utxo --address $paymentAddr $NETWORK_ARG > $outputPath/fullUtxo.out
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
txCount=$(cat $outputPath/balance.out | wc -l)

cardano-cli transaction build-raw \
    ${txIn} \
    --tx-out ${paymentAddr}+$(( ${totalBalance}))  \
    --invalid-hereafter $(( ${currentSlot} + 10000)) \
    --fee 0 \
    --certificate-file $POOL_CERT \
    --certificate-file $DELE_CERT \
    --out-file $outputPath/tx.tmp
    
fee=$(cardano-cli transaction calculate-min-fee \
    --tx-body-file $outputPath/tx.tmp \
    --tx-in-count ${txCount} \
    --tx-out-count 1 \
    $NETWORK_ARG \
    --witness-count 3 \
    --byron-witness-count 0 \
    --protocol-params-file $NETWORK_PATH/params.json | awk '{ print $1 }')

txOut=$((${totalBalance}-${fee}))

cardano-cli transaction build-raw \
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