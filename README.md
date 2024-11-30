# Cardano Stake Pool Operator (SPO) scripts

A collection of scripts and procedures for operating a Stake Pool, DRep or a simple node on Cardano. Developed by:Upstream SPO [UPSTR](https://upstream.org.uk).

```
tree --filesfirst -L 2
.
├── README.md
├── env.example
├── metadata
│   ├── drep.json
│   └── metadata.json
├── scripts
│   ├── common.sh
│   ├── install.sh
│   ├── restart.sh
│   ├── start.sh
│   ├── stop.sh
│   ├── update.sh
│   ├── watch.sh
│   ├── govern
│   ├── install
│   ├── mithril
│   ├── pool
│   ├── query
│   ├── router
│   └── tx
└── services
    ├── cardano-node.service
    ├── mithril.service
    └── ngrok.service
```

### Assumptions

1. Your OS, LAN network, ports and user are already configured. 
2. The Ngrok script requires you to know how to set up your own ngrok account and endpoints.
3. You are comfortable with cardano-node / cardano-cli and SPO requirements 
4. You are comfortable with Linux and managing networks and servers

### Firewall (basic setup)

```
# Allow SSH
sudo ufw allow OpenSSH
# Allow node traffic
sudo ufw allow $NODE_PORT/tcp

# Restart any apply rule
sudo ufw disable
sudo ufw enable
```

---

## Node setup

To install a Cardano node run the following commands, editing your env file to suit your intentions. This table describes the env variables and their available options.

<table>
    <tbody>
        <tr>
            <td>
                <code>NODE_NETWORK</code>
            </td>
            <td>
                <code>sanchonet</code><br/>
                <code>preview</code><br/>
                <code>preprod</code><br/>
                <code>mainnet</code>
            </td>
            <td>
                <p>One of the supported Cardano networks</p>
            </td>
        </tr>
        <tr>
            <td>
                <code>NODE_VERSION</code>
            </td>
            <td>
                <code>10.1.2</code><br/>
            </td>
            <td>
                <p>The current node version. Must be &gt the version defined here.</p>
            </td>
        </tr>
        <tr>
            <td>
                <code>NODE_HOME</code>
            </td>
            <td>
                <code>"/home/upstream/Node"</code>
            </td>
            <td>
                <p>The current node version. Must be &gt the version defined here.</p>
            </td>
        </tr>
        <tr>
            <td>
                <code>NODE_TYPE</code>
            </td>
            <td>
                <code>relay</code><br/>
                <code>producer</code><br/>
                <code>cold</code>
            </td>
            <td>
                <p>The type of node you are running.</p>
            </td>
        </tr>
        <tr>
            <td>
                <code>NODE_USER</code>
            </td>
            <td>
                <code>upstream</code>
            </td>
            <td>
                <p>The user running the node.</p>
            </td>
        </tr>
        <tr>
            <td>
                <code>NODE_PLATFORM</code>
            </td>
            <td>
                <code>linux</code><br/>
                <code>arm</code>
            </td>
            <td>
                <p>The build platform.</p>
            </td>
        </tr>
        <tr>
            <td>
                <code>NODE_BUILD</code>
            </td>
            <td>
                <code>0</code><br/>
                <code>1</code><br/>
                <code>2</code>
            </td>
            <td>
                <p>
                    The build type.<br/>
                    0 = do not build or download.<br/>
                    1 = downloads node binaries.<br/>
                    2 = builds node binaries from source.
                </p>
            </td>
        </tr>
        <tr>
            <td>
                <code>NODE_PORT</code>
            </td>
            <td>
                <code>6000</code>
            </td>
            <td>
                <p>The nodes local port number.</p>
            </td>
        </tr>
        <tr>
            <td>
                <code>NODE_HOSTADDR</code>
            </td>
            <td>
                <code>0.0.0.0</code>
            </td>
            <td>
                <p>The nodes local host address.</p>
            </td>
        </tr>
    </tbody>
</table>

### Node install

```
# Create a directory and pull this repo
mkdir Node && cd Node
git clone https://github.com/devhalls/spo-operational-scripts.git . 
cp -p env.example env

# Edit the env file (see table below for env descriptions and configure based on your intentions)
nano env

# Run the installation script
scripts/install.sh

# Start your node
sudo systemctl start $NETWORK_SERVICE
```

### Mithril db sync

```
# Run the mithril download script
scripts/mithril/download.sh

# Sync the DB with mithril-client (takes some time)
scripts/mithril/sync.sh
```

### Node update

```
# Edit the env with your new NODE_VERSION
nano env

# Update
scripts/update.sh 
```

---

## Register a Stake Pool

To register a stake pool you must have a running **fully synced** node. We can then generate the following assets:

<table>
    <tbody>
        <tr>
            <td>
                <p><code>payment.vkey</code></p>
            </td>
            <td>
                <p>payment verification key</p>
            </td>
        </tr>
        <tr>
            <td>
                <p><code>payment.skey</code></p>
            </td>
            <td>
                <p>payment signing key</p>
            </td>
        </tr>
        <tr>
            <td>
                <p><code>payment.addr</code></p>
            </td>
            <td>
                <p>funded address linked to stake</p>
            </td>
        </tr>
        <tr>
            <td>
                <p><code>stake.vkey</code></p>
            </td>
            <td>
                <p>staking verification key</p>
            </td>
        </tr>
        <tr>
            <td>
                <p><code>stake.skey</code></p>
            </td>
            <td>
                <p>staking signing key</p>
            </td>
        </tr>
        <tr>
            <td>
                <p><code>stake.addr</code></p>
            </td>
            <td>
                <p>registered stake address</p>
            </td>
        </tr>
        <tr>
            <td>
                <p><code>node.skey</code></p>
            </td>
            <td>
                <p>cold signing key</p>
            </td>
        </tr>
        <tr>
            <td>
                <p><code>node.vkey</code></p>
            </td>
            <td>
                <p>cold verification key</p>
            </td>
        </tr>
        <tr>
            <td>
                <p><code>kes.skey</code></p>
            </td>
            <td>
                <p>KES signing key</p>
            </td>
        </tr>
        <tr>
            <td>
                <p><code>kes.vkey</code></p>
            </td>
            <td>
                <p>KES verification key</p>
            </td>
        </tr>
        <tr>
            <td>
                <p><code>vrf.skey</code></p>
            </td>
            <td>
                <p>VRF signing key</p>
            </td>
        </tr>
        <tr>
            <td>
                <p><code>vrf.vkey</code></p>
            </td>
            <td>
                <p>VRF verification key</p>
            </td>
        </tr>
        <tr>
            <td>
                <p><code>node.cert</code></p>
            </td>
            <td>
                <p>operational certificate</p>
            </td>
        </tr>
        <tr>
            <td>
                <p><code>node.counter</code></p>
            </td>
            <td>
                <p>issue counter</p>
            </td>
        </tr>
        <tr>
            <td>
                <p>metadata url</p>
            </td>
            <td>
                Public URL for metadata file
            </td>
        </tr>
        <tr>
            <td>
                <p>metadata hash</p>
            </td>
            <td>
                Hash of the json file
            </td>
        </tr>
    </tbody>
</table>

### Generate stake pool keys and certificates

```
# COLD: Genreate KES keys
scripts/pool/keykes.sh

# COLD: Generate node keys
scripts/pool/keynode.sh

# PRODUCER: Take note of the 'Start period'
scripts/query/tip.sh

# COLD: Genreate node operationsal certificate
scripts/pool/certop.sh <kesPeriod>

# COPY: node.cert to your producer node
# PRODUCER: Generate your node vrf key
scripts/pool/keyvrf.sh
```

### Generate payment and stake keys

```
# PRODUCER: Fetch the chain paramaters
scripts/query/params.sh

# COLD: Generate payment and stake keys
scripts/pool/keypayment.sh
scripts/pool/keystake.sh
scripts/pool/addr.sh

# COPY: The payment.addr to producer node
# EXTERNAL: Fund your payment address (see faucet link at the bottom of this readme)
# PRODUCER: Query the address uxto to ensure funds arrived in your payment.addr
scripts/query/uxto.sh
```

### Registering your stake address

```
# COLD: Generate a stake certificate
scripts/pool/certstake.sh <lovelace>

# COPY: stake.cert to your producer node
# PRODUCER: build stake registration tx  
scripts/tx/buildstakeaddr.sh

# COPY: tx.raw to your cold node 
# COLD: Sign the stage registration transaction tx.raw
scripts/tx/signstakeaddr.sh

# COPY: tx.signed to your producer node and submit
# PRODUCER: Submit the signed transaction. 
scripts/tx/submit.sh
```

### Registering your stake pool

```
# PRODUCER: Take note of your metadata hash
scripts/pool/metadata.sh

# PRODUCER: Take note of the min pool cost
scripts/query/params.sh minPoolCost

# COLD: Gerenate pool registration certificate
scripts/pool/certpool.sh <pledge>, <cost>, <margin>, <relayAddr>, <relayPort>, <metaUrl>, <metaHash>

# COLD: Gerenate pool delegate certificate
scripts/pool/certdeleg.sh 

# COPY: pool.cert to your producer node
# COPY: deleg.cert to your producer node
# PRODUCER: build you pool cert raw transaction
scripts/tx/buildpoolcert.sh

# COPY: tx.raw to your cold node 
# COLD: Sign the pool certificate transaction tx.raw
scripts/tx/signpoolcert.sh

# COPY: tx.signed to your producer node and submit
# PRODUCER: Submit the signed transaction 
scripts/tx/submit.sh
```

### Edit your topology

```
# PRODUCER: Edit your typology
nano node/topology.json

# PRODUCER: Restart the node
scripts/restart.sh
```

---

## Rotate your KES certificate

```
# PRODUCER: Check the current status and node counter
scripts/query/kes.sh

# COLD: Rotate the node
scripts/pool/rotate.sh <startPeriod>

# COPY: new kes to producer node
# PRODUCER: Restart the node
scripts/restart.sh

# PRODUCER: Check the updates applied
scripts/query/kes.sh
```

---

## Regenerate pool certificates

When you need to updated your pool metadata, min cost or other registers pool params you must regenerate your pool.cert and deleg.cert.

```
# Producer node, take note of your metadataHash.txt
scripts/pool/metadata.sh

# Producer node, take note of the min pool cost
scripts/query/params.sh minPoolCost

# Cold node
scripts/pool/certpool.sh <pledge>, <cost>, <margin>, <relayAddr>, <relayPort>, <metaUrl>, <metaHash>
scripts/pool/certdeleg.sh 

# Copy pool.cert to your producer node
# Copy deleg.cert to your producer node
scripts/tx/buildpoolcert.sh 0

# Copy tx.raw to your cold node and sign
scripts/tx/signpoolcert.sh

# Copy tx.signed to your producer node and submit
scripts/tx/submit.sh
```

---

## Register DRep keys

```
# Generate DRep keys
scripts/govern/drepKey.sh

# Generate DRep ID
scripts/govern/drepId.sh 

# Prepare the DRep metadata file and upload to a public location
nano metadata/drep.json 

# Generate the DRep registration certificate
scripts/govern/drepCert.sh <metadata_url> 

# Build a transaction with the drep certificate
scripts/tx/builddrepcert.sh
scripts/tx/signdrepcert.sh
scripts/tx/submit.sh
```

## Govern: vote on a live action

```
# Query the govern action id
scripts/govern/query.sh <action_id>

# Cold node, cast your vote
scripts/govern/vote.sh <govActionId> <govActionIndex> <'yes' | 'no' | 'abstain'>

# Build the transaction containing the vote
scripts/tx/buildvote.sh

# Sign and submit the transaction
scripts/tx/signvote.sh
scripts/tx/submit.sh
```

---

## Links

- [Cardano testnet faucet](https://docs.cardano.org/cardano-testnets/tools/faucet/)


## Examples

```
# Register a stake poool certificate
scripts/pool/certpool.sh 12500000000 170000000 0.01 8.tcp.eu.ngrok.io 24241 https://upstream.org.uk/assets/metadata.json $(cat metadata/metadataHash.txt)
```
