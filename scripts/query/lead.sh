

cardano-cli query leadership-schedule \
    --mainnet \
    --socket-path $HOME/Node/networks/mainnet/db/socket \
    --genesis $HOME/Node/networks/mainnet/shelley-genesis.json \
    --stake-pool-id $(cat $HOME/Node/networks/mainnet/keys/stakepoolid.txt) \
    --vrf-signing-key-file $HOME/Node/networks/mainnet/keys/vrf.skey \
    --current
