#!/bin/bash
# Usage: tx.sh [
#   stake_reg_raw |
#   stake_reg_sign |
#   stake_vote_reg_raw |
#   pool_reg_raw [?stakePoolDeposit] |
#   pool_reg_sign |
#   pool_withdraw_raw |
#   drep_reg_raw |
#   drep_reg_sign |
#   vote_raw |
#   vote_sign [?voteKey] |
#   submit |
#   help [?-h]
# ]
#
# Info:
#
#   - stake_reg_raw) Build raw tx for stake address registration with the stakeAddressDeposit and $STAKE_CERT.
#   - stake_reg_sign) Sign a tx.raw with the $PAYMENT_KEY and $STAKE_KEY (witness-count = 2).
#   - stake_vote_reg_raw) Build raw tx for stake vote registration with $DELE_VOTE_CERT.
#   - pool_reg_raw) Build raw tx for pool registration with the stakePoolDeposit (or passed value) and $POOL_CERT + $DELE_CERT. Optionally pass in stakePoolDeposit to overwrite.
#   - pool_reg_sign) Sign a tx.raw with the $PAYMENT_KEY and $STAKE_KEY and $NODE_KEY (witness-count = 3).
#   - pool_withdraw_raw) Build raw tx for pool withdraw rewards.
#   - drep_reg_raw) Build raw tx for drep registration with the $DREP_CERT.
#   - drep_reg_sign) Sign a tx.raw with the $PAYMENT_KEY and $DREP_KEY (witness-count = 2).
#   - vote_raw) Build raw tx from a vote.raw file (vote.raw is generated using govern.sh functions).
#   - vote_sign) Sign a tx.raw vote transaction with the vote.raw and $PAYMENT_KEY (witness-count = 2).
#   - submit) Submit a tx.signed to chain.
#   - help) View this files help. Default value if no option is passed.

source "$(dirname "$0")/common.sh"

tx_stake_reg_raw() {
    exit_if_not_producer
    paymentAddr=$(cat "${PAYMENT_ADDR}")
    outputPath=$NETWORK_PATH/temp
    currentSlot=$($CNCLI conway query tip $NETWORK_ARG --socket-path $NETWORK_SOCKET_PATH | jq -r '.slot')
    stakeAddressDeposit=$(cat $NETWORK_PATH/params.json | jq -r '.stakeAddressDeposit')
    txIn=""
    totalBalance=0
    txCount=0

    $CNCLI conway query utxo --socket-path $NETWORK_SOCKET_PATH --address $paymentAddr --output-text $NETWORK_ARG >$outputPath/fullUtxo.out
    tail -n +3 $outputPath/fullUtxo.out | sort -k3 -nr >$outputPath/balance.out
    cat $outputPath/balance.out
    while read -r utxo; do
        type=$(awk '{ print $6 }' <<<"${utxo}")
        if [[ ${type} == 'TxOutDatumNone' ]]; then
            inAddr=$(awk '{ print $1 }' <<<"${utxo}")
            idx=$(awk '{ print $2 }' <<<"${utxo}")
            utxoBalance=$(awk '{ print $3 }' <<<"${utxo}")
            totalBalance=$((${totalBalance} + ${utxoBalance}))
            txIn="${txIn} --tx-in ${inAddr}#${idx}"
        fi
    done <$outputPath/balance.out
    txCount=$(cat $outputPath/balance.out | wc -l)

    $CNCLI conway transaction build-raw \
        ${txIn} \
        --tx-out ${paymentAddr}+$((${totalBalance} - ${stakeAddressDeposit})) \
        --invalid-hereafter $((${currentSlot} + 10000)) \
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

    txOut=$((${totalBalance} - ${stakeAddressDeposit} - ${fee}))

    $CNCLI conway transaction build-raw \
        ${txIn} \
        --tx-out ${paymentAddr}+${txOut} \
        --invalid-hereafter $((${currentSlot} + 10000)) \
        --fee ${fee} \
        --certificate-file $STAKE_CERT \
        --out-file $outputPath/tx.raw

    rm $outputPath/fullUtxo.out
    rm $outputPath/balance.out
    rm $outputPath/tx.tmp

    print 'TX' "Stake address deposit: ${stakeAddressDeposit}"
    print 'TX' "Available balance: ${totalBalance}"
    print 'TX' "Num of UTXOs: ${txCount}"
    print 'TX' "Fee: ${fee}"
    print 'TX' "Change output: ${txOut}"
    print 'TX' "File output: ${outputPath}/tx.raw" $green
}

tx_stake_reg_sign() {
    exit_if_not_cold
    outputPath=$NETWORK_PATH/temp

    $CNCLI conway transaction sign \
        --tx-body-file $outputPath/tx.raw \
        --signing-key-file $PAYMENT_KEY \
        --signing-key-file $STAKE_KEY \
        $NETWORK_ARG \
        --out-file $outputPath/tx.signed

    rm $outputPath/tx.raw
    print 'TX' "File output: ${outputPath}/tx.signed" $green
}

tx_stake_vote_reg_raw() {
    exit_if_not_producer
    outputPath=$NETWORK_PATH/temp

    $CNCLI conway transaction build \
        $NETWORK_ARG \
        --socket-path $NETWORK_SOCKET_PATH \
        --tx-in $($CNCLI query utxo --address $(<$PAYMENT_ADDR) $NETWORK_ARG --socket-path $NETWORK_SOCKET_PATH --output-json | jq -r 'keys[0]') \
        --change-address $(<$PAYMENT_ADDR) \
        --certificate-file $DELE_VOTE_CERT \
        --witness-override 2 \
        --out-file $outputPath/tx.raw

    print 'TX' "File output: ${outputPath}/tx.raw" $green
}

tx_pool_reg_raw() {
    exit_if_not_producer
    paymentAddr=$(cat "${PAYMENT_ADDR}")
    outputPath=$NETWORK_PATH/temp
    currentSlot=$($CNCLI conway query tip $NETWORK_ARG --socket-path $NETWORK_SOCKET_PATH | jq -r '.slot')
    stakePoolDeposit=${1:-$(cat $NETWORK_PATH/params.json | jq -r '.stakePoolDeposit')}
    txIn=""
    totalBalance=0
    txCount=0

    $CNCLI conway query utxo --socket-path $NETWORK_SOCKET_PATH --address $paymentAddr --output-text $NETWORK_ARG >$outputPath/fullUtxo.out
    tail -n +3 $outputPath/fullUtxo.out | sort -k3 -nr >$outputPath/balance.out
    cat $outputPath/balance.out
    while read -r utxo; do
        type=$(awk '{ print $6 }' <<<"${utxo}")
        if [[ ${type} == 'TxOutDatumNone' ]]; then
            inAddr=$(awk '{ print $1 }' <<<"${utxo}")
            idx=$(awk '{ print $2 }' <<<"${utxo}")
            utxoBalance=$(awk '{ print $3 }' <<<"${utxo}")
            totalBalance=$((${totalBalance} + ${utxoBalance}))
            txIn="${txIn} --tx-in ${inAddr}#${idx}"
        fi
    done <$outputPath/balance.out
    txCount=$(cat $outputPath/balance.out | wc -l)

    $CNCLI conway transaction build-raw \
        ${txIn} \
        --tx-out ${paymentAddr}+$((${totalBalance} - ${stakePoolDeposit})) \
        --invalid-hereafter $((${currentSlot} + 10000)) \
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

    txOut=$((${totalBalance} - ${stakePoolDeposit} - ${fee}))

    $CNCLI conway transaction build-raw \
        ${txIn} \
        --tx-out ${paymentAddr}+${txOut} \
        --invalid-hereafter $((${currentSlot} + 10000)) \
        --fee ${fee} \
        --certificate-file $POOL_CERT \
        --certificate-file $DELE_CERT \
        --out-file $outputPath/tx.raw

    rm $outputPath/fullUtxo.out
    rm $outputPath/balance.out
    rm $outputPath/tx.tmp

    print 'TX' "Stake pool deposit: ${stakePoolDeposit}"
    print 'TX' "Available balance: ${totalBalance}"
    print 'TX' "Num of UTXOs: ${txCount}"
    print 'TX' "Fee: ${fee}"
    print 'TX' "Change output: ${txOut}"
    print 'TX' "File output: ${outputPath}/tx.raw" $green
}

tx_pool_reg_sign() {
    exit_if_not_cold
    outputPath=$NETWORK_PATH/temp

    $CNCLI conway transaction sign \
        --tx-body-file $outputPath/tx.raw \
        --signing-key-file $PAYMENT_KEY \
        --signing-key-file $NODE_KEY \
        --signing-key-file $STAKE_KEY \
        $NETWORK_ARG \
        --out-file $outputPath/tx.signed

    rm $outputPath/tx.raw
    print 'TX' "File output: ${outputPath}/tx.signed" $green
}

tx_pool_withdraw_raw() {
    exit_if_not_producer
    outputPath=$NETWORK_PATH/temp/tx.raw
    rewards="$(bash $(dirname "$0")/query.sh rewards rewardAccountBalance)"

    $CNCLI conway transaction build \
        $NETWORK_ARG \
        --socket-path $NETWORK_SOCKET_PATH \
        --tx-in $($CNCLI query utxo --socket-path $NETWORK_SOCKET_PATH --address $(<$PAYMENT_ADDR) $NETWORK_ARG --output-json | jq -r 'keys[0]') \
        --withdrawal "$(<$STAKE_ADDR)+$rewards" \
        --change-address $(<$PAYMENT_ADDR) \
        --witness-override 2 \
        --out-file $outputPath

    print 'TX' "File output: $outputPath" $green
}

tx_drep_reg_raw() {
    exit_if_not_producer
    outputPath=$NETWORK_PATH/temp

    $CNCLI conway transaction build \
        $NETWORK_ARG \
        --socket-path $NETWORK_SOCKET_PATH \
        --tx-in $($CNCLI query utxo --address $(<$PAYMENT_ADDR) $NETWORK_ARG --socket-path $NETWORK_SOCKET_PATH --output-json | jq -r 'keys[0]') \
        --change-address $(<$PAYMENT_ADDR) \
        --certificate-file $DREP_CERT \
        --witness-override 2 \
        --out-file $outputPath/tx.raw

    print 'TX' "File output: ${outputPath}/tx.raw" $green
}

tx_drep_reg_sign() {
    exit_if_not_cold
    outputPath=$NETWORK_PATH/temp

    $CNCLI conway transaction sign \
        $NETWORK_ARG \
        --tx-body-file $outputPath/tx.raw \
        --signing-key-file $PAYMENT_KEY \
        --signing-key-file $DREP_KEY \
        --out-file $outputPath/tx.signed

    rm $outputPath/tx.raw
    print 'TX' "File output: ${outputPath}/tx.signed" $green
}

tx_vote_raw() {
    exit_if_not_producer
    govActionId=${1}
    govActionIndex=${2}
    votePath=$NETWORK_PATH/temp/vote.raw

    $CNCLI conway transaction build \
        $NETWORK_ARG --socket-path $NETWORK_SOCKET_PATH \
        --tx-in $($CNCLI query utxo --address $(<$PAYMENT_ADDR) $NETWORK_ARG --socket-path $NETWORK_SOCKET_PATH --output-json | jq -r 'keys[0]') \
        --change-address $(<$PAYMENT_ADDR) \
        --vote-file $votePath \
        --witness-override 2 \
        --out-file $NETWORK_PATH/temp/tx.raw

    rm $votePath
    print 'TX' "File output: $NETWORK_PATH/temp/tx.raw" $green
}

tx_vote_sign() {
    exit_if_not_cold
    keyFile=${1}
    tempPath=$NETWORK_PATH/temp
    votePath=$NETWORK_PATH/temp/vote.raw

    $CNCLI conway transaction sign \
        --tx-body-file $tempPath/tx.raw \
        --signing-key-file $votePath \
        --signing-key-file $PAYMENT_KEY \
        --out-file $tempPath/tx.signed

    rm $tempPath/tx.raw
    print 'TX' "File output: $tempPath/tx.signed" $green
}

# @todo complete new functions for tx building below
# scripts/tx.sh build 0 --certificate-file 1 --certificate-file 2

tx_in() {
    paymentAddress=$(<$PAYMENT_ADDR)
    outputPath=$NETWORK_PATH/temp
    totalBalance=0
    txCount=0
    txIn=""

    # Calculate.
    bash $(dirname "$0")/query.sh uxto >$outputPath/uxto.out
    tail -n +3 $outputPath/uxto.out | sort -k3 -nr >$outputPath/balance.out
    cat $outputPath/balance.out
    while read -r utxo; do
        type=$(awk '{ print $6 }' <<<"${utxo}")
        if [[ ${type} == 'TxOutDatumNone' ]]; then
            inAddr=$(awk '{ print $1 }' <<<"${utxo}")
            idx=$(awk '{ print $2 }' <<<"${utxo}")
            utxoBalance=$(awk '{ print $3 }' <<<"${utxo}")
            totalBalance=$((${totalBalance} + ${utxoBalance}))
            txIn="${txIn} --tx-in ${inAddr}#${idx}"
        fi
    done <$outputPath/balance.out

    # Output.
    echo totalBalance: ${totalBalance}
    echo txCount: $(cat $outputPath/balance.out | wc -l)
    echo txIn: ${txIn}

    # Clean up.
    rm $outputPath/uxto.out
    rm $outputPath/balance.out
}

tx_out() {
    amount=${1}
    totalBalance=${2}
    txCount=${3}
    witnessCount=${4}
    txIn=$(get_option --tx-in "${@:5}")
    params=${@:7}

    paymentAddress=$(<$PAYMENT_ADDR)
    currentSlot=$(bash $(dirname "$0")/query.sh tip slot)
    outputPath=$NETWORK_PATH/temp

    # Calculate the fee.
    $CNCLI conway transaction build-raw \
        ${txIn} \
        --tx-out ${paymentAddress}+$((${totalBalance} - ${amount})) \
        --invalid-hereafter $((${currentSlot} + 10000)) \
        --fee 0 \
        --out-file $outputPath/tx.tmp \
        ${params}

    fee=$($CNCLI conway transaction calculate-min-fee \
        --tx-body-file $outputPath/tx.tmp \
        --tx-in-count ${txCount} \
        --tx-out-count 1 \
        $NETWORK_ARG \
        --witness-count $witnessCount \
        --byron-witness-count 0 \
        --protocol-params-file $NETWORK_PATH/params.json | awk '{ print $1 }')
    txOut=$((${totalBalance} - ${amount} - ${fee}))

    # Build the tx.raw.
    $CNCLI conway transaction build-raw \
        ${txIn} \
        --tx-out ${paymentAddress}+${txOut} \
        --invalid-hereafter $((${currentSlot} + 10000)) \
        --fee ${fee} \
        ${params} \
        --out-file $outputPath/tx.raw

    # Output.
    echo fee: $fee
    echo txRaw: $outputPath/tx.raw

    # Clean up.
    rm $outputPath/tx.tmp
}

tx_build() {
    amount=${1:-0}
    witnessCount=${2}
    params="${@:3}"

    # Calculate tx input.
    txInput=$(tx_in)
    totalBalance=$(get_param "$txInput" "totalBalance")
    txCount=$(get_param "$txInput" "txCount")
    txIn=$(get_param "$txInput" "txIn")

    # Calculate tx fee and tx.raw.
    txOutput=$(tx_out $amount $totalBalance $txCount $witnessCount $txIn $params)

    fee=$(get_param "$txOutput" "fee")
    txRaw=$(get_param "$txOutput" "txRaw")

    # Output.
    echo fee: $fee
    print 'TX' "File output: $txRaw" $green
}

tx_sign() {
    signers=$(get_option --signing-key-file "$@")
    tempPath=$NETWORK_PATH/temp
    votePath=$NETWORK_PATH/temp/vote.raw

    $CNCLI conway transaction sign \
        --tx-body-file $tempPath/tx.raw \
        $signers \
        --out-file $tempPath/tx.signed

    rm $tempPath/tx.raw
    print 'TX' "File output: $tempPath/tx.signed" $green
}

tx_submit() {
    exit_if_not_producer
    outputPath=$NETWORK_PATH/temp

    $CNCLI conway transaction submit \
        --tx-file $outputPath/tx.signed \
        --socket-path $NETWORK_SOCKET_PATH \
        $NETWORK_ARG

    rm $outputPath/tx.signed
}

case $1 in
    stake_reg_raw) tx_stake_reg_raw ;;
    stake_reg_sign) tx_stake_reg_sign ;;
    stake_vote_reg_raw) tx_stake_vote_reg_raw ;;
    pool_reg_raw) tx_pool_reg_raw "${@:2}" ;;
    pool_reg_sign) tx_pool_reg_sign ;;
    pool_withdraw_raw) tx_pool_withdraw_raw ;;
    drep_reg_raw) tx_drep_reg_raw ;;
    drep_reg_sign) tx_drep_reg_sign ;;
    vote_raw) tx_vote_raw ;;
    vote_sign) tx_vote_sign ;;
    in) tx_in "${@:2}" ;;
    out) tx_out "${@:2}" ;;
    build) tx_build "${@:2}" ;;
    sign) tx_sign "${@:2}" ;;
    submit) tx_submit ;;
    help) help "${2:-"--help"}" ;;
    *) help "${1:-"--help"}" ;;
esac
