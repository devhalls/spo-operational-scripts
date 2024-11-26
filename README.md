# Cardano Stake Pool Operator (SPO) scripts

A collection of scripts and procedures for operating a stake pool on Cardano.

Developed by Upstream SPO [UPSTR](https://upstream.org.uk)

### Assumptions

1. Your OS, LAN network, ports and user are configured
2. You are comfortable with cardano-node / cardano-cli and SPO requirements 
3. You are comfortable with Linux and managing networks and servers

### Firewall

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

## Node install

```
# Create a directory and pull this repo
mkdir Node && cd Node
git clone https://github.com/devhalls/spo-operational-scripts.git . 
cp -p env.example env

# Edit the env file (see table below for env descriptions)
nano env

# Run the installation script
scripts/install.sh

# Start your node
sudo systemctl start $NETWORK_SERVICE
```

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

## Mithril db sync

```
# Run the mithril download script
scripts/mithril/install/download.sh

# Sync the DB with mithril-client (takes some time)
scripts/mithril/install/sync.sh
```

## Node update

```
# Edit the env with your new NODE_VERSION
nano env

# Update
scripts/update.sh 
```

---

## Register a Stake Pool

To register a stake pool you must have a running fully synced relay node. We can then generate the following assets:

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
# Producer node
scripts/pool/keykes.sh

# Cold node
scripts/pool/keynode.sh

# Producer node, take note of the 'Start period'
scripts/query/tip.sh

# Copy kes.vkey to your cold node
# Cold node
scripts/pool/certop.sh <kesPeriod>

# Copy node.cert to your producer node
# Producer node
scripts/pool/keyvrf.sh
```

### Generate payment and stake keys

```
# Producer node
scripts/query/params.sh

# Cold node
scripts/pool/keypayment.sh
scripts/pool/keystake.sh
scripts/pool/addr.sh

# Copy payment.addr to your hot environment
# Fund your payment address (see faucet link at the bottom)
# Producer node
scripts/query/uxto.sh
```

### Registering your stake address

```
# Cold node
scripts/pool/certstake.sh <lovelace>

# Copy stake.cert to your producer node and build tx
scripts/tx/buildstakeaddr.sh

# Copy tx.raw to your cold node and sign
scripts/tx/signstakeaddr.sh

# Copy tx.signed to your producer node and submit
scripts/tx/submit.sh
```

### Registering your stake pool

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
scripts/tx/buildpoolcert.sh

# Copy tx.raw to your cold node and sign
scripts/tx/signpoolcert.sh

# Copy tx.signed to your producer node and submit
scripts/tx/submit.sh
```

### Edit your topology

```
# Edit your typology
nano node/topology.json
```

---

## Rotate your KES certificate

```
# Check the current status and node counter
scripts/query/kes.sh

# Rotate the node
scripts/pool/rotate.sh <startPeriod>

# Restart the node
scripts/restart.sh

# Check the updates applied
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
