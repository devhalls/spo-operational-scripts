#!/bin/bash

# Info : Build transaction to register a stake address.
#      : Expects env with set variables.
# Use  : cd $NODE_HOME
#      : scripts/gen/addrstake.sh <sanchonet | preview | preprod | mainnet>

source "$(dirname "$0")/../../networks/${3:-"preview"}/env"

stakeAddressDeposit=$(cat $NETWORK_PATH/params.json | jq -r '.stakeAddressDeposit')
addrFrom=$(cat "${PAYMENT_ADDR}")
outputPath=${NODE_HOME}/temp
currentSlot=$(cardano-cli query tip $NETWORK_ARG | jq -r '.slot')

echo list UXTO: 
cardano-cli query utxo --address $addrFrom $NETWORK_ARG > $outputPath/fullUtxo.out
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

echo Stake address deposit: ${stakeAddressDeposit}
echo Current slot: ${currentSlot}
echo Available balance: ${totalBalance}
echo Num of UTXOs: ${txCount}
echo Fee: ${fee}
echo Change output: ${txOut}
echo File output: ${outputPath}/tx.raw
