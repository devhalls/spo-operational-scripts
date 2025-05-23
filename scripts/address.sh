#!/bin/bash
# Usage: address.sh (
#   generate_payment_keys |
#   generate_stake_keys |
#   generate_payment_address |
#   generate_stake_address |
#   generate_stake_reg_cert [deposit <INT>] |
#   generate_stake_del_cert |
#   generate_stake_vote_cert (delegateTo <STRING<'drep'|'script'|'abstain'|'no-confidence'>>) |
#   help [?-h <BOOLEAN>]
# )
#
# Info:
#
#   - generate_payment_keys) Generate a payment key pair.
#   - generate_stake_keys) Generate a stake key pair.
#   - generate_payment_address) Generate a payment address from a payment key.
#   - generate_stake_address) Generate a stake address from a stake key.
#   - generate_stake_reg_cert) Generate a stake registration certificate. Requires the deposit param in lovelace.
#   - generate_stake_del_cert) Generate a stake delegation certificate.
#   - generate_stake_vote_cert) Generate a vote delegation certificate delegating your voting power. Can be 'drep <drepId>' | 'script <scriptHash>' | 'abstain' | 'no-confidence'.
#   - help) View this files help. Default value if no option is passed.

source "$(dirname "$0")/common.sh"

address_generate_payment_keys() {
    exit_if_not_cold
    if [ -f $PAYMENT_KEY ]; then
        confirm "Payment keys already exist! 'yes' to overwrite, 'no' to cancel"
    fi
    $CNCLI conway address key-gen \
        --verification-key-file $PAYMENT_VKEY \
        --signing-key-file $PAYMENT_KEY
    print 'ADDRESS' "Payment keys created at $NETWORK_PATH/keys" $green
}

address_generate_stake_keys() {
    exit_if_not_cold
    if [ -f $STAKE_KEY ]; then
        confirm "Stake keys already exist! 'yes' to overwrite, 'no' to cancel"
    fi
    $CNCLI conway stake-address key-gen \
        --verification-key-file $STAKE_VKEY \
        --signing-key-file $STAKE_KEY
    print 'ADDRESS' "Stake keys created at $NETWORK_PATH/keys" $green
}

address_generate_payment_address() {
    exit_if_not_producer
    if [ -f $PAYMENT_ADDR ]; then
        confirm "Payment address already exists! 'yes' to overwrite, 'no' to cancel"
    fi
    $CNCLI conway address build \
        --payment-verification-key-file $PAYMENT_VKEY \
        --stake-verification-key-file $STAKE_VKEY \
        --out-file $PAYMENT_ADDR \
        $NETWORK_ARG
    print 'ADDRESS' "Payment address: $(cat $PAYMENT_ADDR)" $green
}

address_generate_stake_address() {
    exit_if_not_producer
    if [ -f $STAKE_ADDR ]; then
        confirm "Stake address already exists! 'yes' to overwrite, 'no' to cancel"
    fi
    $CNCLI conway stake-address build \
        --stake-verification-key-file $STAKE_VKEY \
        --out-file $STAKE_ADDR \
        $NETWORK_ARG
    print 'ADDRESS' "Stake address: $(cat $STAKE_ADDR)" $green
}

address_generate_stake_reg_cert() {
    exit_if_not_cold
    if [ -f $STAKE_CERT ]; then
        confirm "Certificate already exists! 'yes' to overwrite, 'no' to cancel"
    fi
    $CNCLI conway stake-address registration-certificate \
        --stake-verification-key-file $STAKE_VKEY \
        --key-reg-deposit-amt $1 \
        --out-file $STAKE_CERT
    print 'ADDRESS' "Stake registration certificate created at $STAKE_CERT" $green
}

address_generate_stake_del_cert() {
    exit_if_not_cold
    if [ -f $DELE_CERT ]; then
        confirm "Certificate already exists! 'yes' to overwrite, 'no' to cancel"
    fi
    $CNCLI conway stake-address stake-delegation-certificate \
        --stake-verification-key-file $STAKE_VKEY \
        --cold-verification-key-file $NODE_VKEY \
        --out-file $DELE_CERT
    print 'ADDRESS' "Stake delegation certificate created at $DELE_CERT" $green
}

address_generate_stake_vote_cert() {
    exit_if_not_cold
    if [ -f $DELE_VOTE_CERT ]; then
        confirm "Certificate already exists! 'yes' to overwrite, 'no' to cancel"
    fi
    param=
    case $1 in
        drep) param="--drep-key-hash $2" ;;
        script) param="--drep-script-hash $2" ;;
        abstain) param="--always-abstain" ;;
        no-confidence) param="--always-no-confidence" ;;
        *) exit 1 ;;
    esac
    $CNCLI conway stake-address vote-delegation-certificate \
        --stake-verification-key-file $STAKE_VKEY \
        $param \
        --out-file $DELE_VOTE_CERT
    print 'ADDRESS' "Voting delegation certificate created for: $@" $green
}

case $1 in
    generate_payment_keys) address_generate_payment_keys ;;
    generate_payment_address) address_generate_payment_address ;;
    generate_stake_keys) address_generate_stake_keys ;;
    generate_stake_address) address_generate_stake_address ;;
    generate_stake_reg_cert) address_generate_stake_reg_cert "${@:2}" ;;
    generate_stake_del_cert) address_generate_stake_del_cert ;;
    generate_stake_vote_cert) address_generate_stake_vote_cert "${@:2}" ;;
    help) help "${2:-"--help"}" ;;
    *) help "${1:-"--help"}" ;;
esac
