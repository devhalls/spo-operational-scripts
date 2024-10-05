rotate.sh

source "$(dirname "$0")/../../networks/${1}/env"
source "$(dirname "$0")/../common/common.sh"
help 18 2 ${@} || exit

kesPeriod="${2}"

cardano-cli node key-gen-KES \
    --verification-key-file kes.vkey \
    --signing-key-file kes.skey

cat $HOME/cold-keys/node.counter

cardano-cli node issue-op-cert \
    --kes-verification-key-file $KES_VKEY \
    --cold-signing-key-file $NODE_KEY \
    --operational-certificate-issue-counter $KES_COUNTER \
    --kes-period $kesPeriod \
    --out-file $NODE_CERT

print 'KES' "Copy node.cert and kes.skey back to your block producer node"
print 'KES' "Then restart your node with scripts/restart.sh $NODE_NETWORK"
