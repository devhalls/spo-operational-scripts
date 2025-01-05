# Cardano Stake Pool Operator (SPO) scripts

A collection of scripts and procedures for operating a Stake Pool, DRep or a Cardano node. Developed by Upstream Stake Pool [UPSTR](https://upstream.org.uk).

<details>
<summary>File tree</summary>

```
tree --filesfirst -L 3
.
├── LICENSE
├── README.md
├── env.example
├── metadata
│   ├── drep.example.json
│   └── metadata.example.json
├── scripts
│   ├── address.sh
│   ├── common.sh
│   ├── govern.sh
│   ├── network.sh
│   ├── node.sh
│   ├── pool.sh
│   ├── query.sh
│   ├── tx.sh
│   └── node
│       ├── build.sh
│       ├── download.sh
│       ├── install.sh
│       ├── mithril.sh
│       └── update.sh
└── services
    ├── cardano-node.service
    ├── grafana-mithril-dashboard.json
    ├── grafana-node-dashboard.json
    ├── mithril.service
    ├── ngrok.service
    └── prometheus.yml
```
</details>

<details>
<summary>Assumptions</summary>

1. Your OS, LAN network, ports and user are already configured. 
2. The Ngrok script requires you to know how to set up your own ngrok account and endpoints.
3. You are comfortable with cardano-node / cardano-cli and SPO requirements 
4. You are comfortable with Linux and managing networks and servers
5. You are able to setup your cold node by copying the binaries, scripts and keys securely as required.
</details>

---

## Node setup

This table describes the env variables you most likely need to adjust to suit your system and their available options. Read through these options before proceeding to the installation.

<details>
<summary>env variables</summary>

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
                <code>10.1.3</code><br/>
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
        <tr>
            <td>
                <code>NODE_CARDANOSCAN_API</code>
            </td>
            <td>
                <code>API key</code>
            </td>
            <td>
                <p>A Cardanoscan.io API key used to fetch pool data displayed in Grafana.</p>
            </td>
        </tr>
    </tbody>
</table>

</details>

### Node install

Get started by creating a directory and pulling this repo, and edit the env file (see table below for env descriptions and configure).

```
mkdir Cardano && cd Cardano
git clone https://github.com/devhalls/spo-operational-scripts.git . 
cp -p env.example env && nano env
```

When your env is configured, run the installation.

```
scripts/node.sh install
```

### Mithril db sync

Once installation is complete, download the mithril binaries and run mithril sync.

```
scripts/node.sh mithril download
scripts/node.sh mithril sync
```

### Node start, stop and restart

After installation is complete you can start, stop or restart the node service.

```
scripts/node.sh start
scripts/node.sh stop
scripts/node.sh restart
```

### Node update

When you would like to update the node, edit the env with your new target NODE_VERSION and run the node update script.

```
nano env
scripts/node.sh update 
```

### Firewall

This is an example of allowing the node port through a firewall, its expected you will secure your node as appropriate for mainnet releases.

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

## Registering a Stake Pool

To register a stake pool you must have a running **fully synced** node. We can then generate the following assets:

<details>
<summary>pool assets</summary>

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
</details>

### Generate stake pool keys and certificates

Start your pool registration by generating node keys and a node operational certificate, along with your KES keys and VRF keys.

```
# PRODUCER: Query network params and take note of the 'KES period'
scripts/query.sh params
scripts/query.sh kes_period

# COLD: Genreate node keys and operational certificate
scripts/pool.sh generate_kes_keys
scripts/pool.sh generate_node_keys
scripts/pool.sh generate_node_op_cert <KES period>

# COPY: node.cert to your producer node
# PRODUCER: Generate your node vrf key
scripts/pool.sh generate_vrf_keys
```

### Generate payment and stake keys

Create payment keys, stake keys and generate addresses from the keys. Ensure you fund your payment addres and query the chain to confirm your have UXTOs.

```
# COLD: Generate payment and stake keys
scripts/address.sh generate_payment_keys
scripts/address.sh generate_stake_keys
scripts/address.sh generate_payment_address
scripts/address.sh generate_stake_address

# COPY: The payment.addr and stake.addr to your producer node
# EXTERNAL: Fund your payment address (see faucet link at the bottom of this readme)
# PRODUCER: Query the address uxto to ensure funds arrived in your payment.addr
scripts/query.sh uxto
```

### Registering your stake address

Create a stake address certificate and submit the transaction to complete the registration.

```
# COLD: Get the stakeAddressDeposit value then generate a stake certificate
scripts/query.sh params stakeAddressDeposit
scripts/address.sh generate_stake_reg_cert <lovelace>

# COPY: stake.cert to your producer node
# PRODUCER: build stake registration tx  
scripts/tx.sh stake_reg_raw

# COPY: tx.raw to your cold node 
# COLD: Sign the stage registration transaction tx.raw
scripts/tx.sh stake_reg_sign

# COPY: tx.signed to your producer node
# PRODUCER: Submit the signed transaction 
scripts/tx.sh submit
```

### Registering your stake pool

Create a pool registration certificates and submit the transaction to complete the registration.

```
# PRODUCER: Generate your metadata hash and take note along with the min pool cost
scripts/pool.sh generate_pool_meta_hash
scripts/query.sh params minPoolCost

# COLD: Gerenate pool registration certificate and pool delegate certificate
scripts/pool.sh generate_pool_reg_cert <pledge>, <cost>, <margin>, <relayAddr>, <relayPort>, <metaUrl>, <metaHash>
scripts/address.sh generate_stake_del_cert 

# COPY: pool.cert and deleg.cert to your producer node
# PRODUCER: build you pool cert raw transaction
scripts/tx.sh pool_reg_raw

# COPY: tx.raw to your cold node 
# COLD: Sign the pool certificate transaction tx.raw
scripts/tx.sh pool_reg_sign

# COPY: tx.signed to your producer node
# PRODUCER: Submit the signed transaction 
scripts/tx.sh submit

# COLD: Now you have registered your pool, get your pool.id
scripts/pool.sh get_pool_id

# COPY: pool.id to your producer node, and to your replay node 
```

### Edit topology and restart the producer

To complete pool registration edit your topology to suit your replay configuration and restart your producer node.

```
# PRODUCER: Edit your typology and add your relay configuration
nano cardano-node/topology.json

# PRODUCER: Update your env NODE_TYPE=producer
nano env

# PRODUCER: Then restart the producer
scripts/node.sh restart
```

---

## Managing a Stake Pool

As an SPO there are a few things you must do to keep a producing block producing pool.

### Monitoring your pool

Knowing what's going on under the hood is essential to running a node. 

```
# Watch the node service logs
scripts/node.sh watch

¢ Display the node service status
scripts/node.sh status

# Run the gLiveView script
scripts/node.sh view

# Read file contents from the node directories 
scripts/query.sh config topology.json
scripts/query.sh key stake.addr

# Query your KES period and state
scripts/query.sh kes_period
scripts/query.sh kes_state

# Query the tip or chain params, with an optional param name
scripts/query.sh tip
scripts/query.sh tip epoch
scripts/query.sh params
scripts/query.sh params treasuryCut

# Query node prometheus metrics
scripts/query.sh metrics
scripts/query.sh metrics cardano_node_metrics_peerSelection_warm
```

### Monitoring with Grafana

View your node state via Grafana dashboards makes it easy to manage your nodes. Once you have installed the necessary packages and configs restart your nodes and you can visit the dashboard.
Dashboard: MONITOR_NODE_IP:3000 
Username: admin
Password: admin (change your password after first login)

```
# ALL NODES: Install prometheus explorer on all nodes
scripts/node.sh install prometheus_explorer

# MONITOR: Install grafana on the monitoring node only
scripts/node.sh install grafana

# ALL NODES: Check the service status
scripts/node.sh watch_prom_ex
scripts/node.sh status_prom_ex

# MONITOR: Check the service status
scripts/node.sh watch_prom
scripts/node.sh watch_grafana
scripts/node.sh status_prom
scripts/node.sh status_grafana

# ALL NODES: Restart the prometheus services
scripts/node.sh restart_prom

# MONITOR: Restart the grafana services
scripts/node.sh restart_grafana

# MONITOR: Edit your prometheus config to collect data from all your replays, then restart
sudo nano /etc/prometheus/prometheus.yml
scripts/node.sh restart_prometheus

# MONITOR: You may need to add the prometheus user to the folders group to avoid permission issues
sudo usermod -a -G upstream prometheus

# MONITOR: You may also need to change the user in the prometheus.yml if you still experience permissions issues
sudo nano /etc/prometheus/prometheus.yml
```

To enable metrics from Cardanoscan API, set the env API key in NODE_CARDANOSCAN_API, then run the following commands:

```
# MONITOR: create the pool.id file and paste in your 'Pool ID' which you can get from https://cardanoscan.io (or generate it on your cold device)
nano cardano-node/keys/pool.id

# MONITOR: Check you can retrieve stats, and check if theres no error in the response
scripts/pool.sh get_stats

# If successful (you see stats output) setup a crontab to fetch data periodically
crontab -e

# Get data from Cardanoscan every hour at 5 past the hour
5 * * * * /home/upstream/Cardano/scripts/pool.sh get_stats
```

### Backing up your pool

It's vitally import you make multiple backups of your node cold keys, this is what gives you control over your node. You can also backup your producer and relays to make redeployment simpler.  

```
# COLD: Backup the keys.
.
├── $NETWORK_PATH/keys

# PRODUCER: Optionally backup the below directories and env configuration, EXCLUDING the $NETWORK_PATH/db folder which contains the blockchain database.
.
├── env
├── metadata
├── $NETWORK_PATH
```

### Rotate your KES

You must rotate your KES keys every 90 days or you will not be able to produce blocks.

```
# PRODUCER: Check the current status and take note of the 'kesPeriod'
scripts/query.sh kes_state
scripts/query.sh kes_period

# COLD: Rotate the node
scripts/pool.sh rotate_kes <kesPeriod>

# COPY: node.cert and kes.skey to producer node
# PRODUCER: Restart the node
scripts/node.sh restart

# PRODUCER: Check the updates have applied
scripts/query.sh kes_state
```

### Regenerate pool certificates

When you need to update your pool metadata, min cost or other pool params you must regenerate your pool.cert and deleg.cert using the same steps as when you first created these.

```
# PRODUCER: Generate your metadata hash and take note along with the min pool cost
scripts/pool.sh generate_pool_meta_hash
scripts/query.sh params minPoolCost

# COLD: Gerenate pool registration certificate and pool delegate certificate
scripts/pool.sh generate_pool_reg_cert <pledge>, <cost>, <margin>, <relayAddr>, <relayPort>, <metaUrl>, <metaHash>
scripts/address.sh generate_stake_del_cert 

# COPY: pool.cert and deleg.cert to your producer node
# PRODUCER: build you pool cert raw transaction passing in 0 as a deposit for renewals
scripts/tx.sh pool_reg_raw 0

# COPY: tx.raw to your cold node 
# COLD: Sign the pool certificate transaction tx.raw
scripts/tx.sh pool_reg_sign

# COPY: tx.signed to your producer node
# PRODUCER: Submit the signed transaction 
scripts/tx.sh submit
```

### Delegating your voting power

In order to withdraw your SPO rewards you will need to participate in Cardano Governance by delegating your voting power. You have 4 possibilities when choosing how you wish to participate, listed below. Along with these you can also register your stake address as a DRep and participate in Governance directly as your own representative.

1. delegate to a DRep who can vote on your behalf
1. delegate to a DRep script who can vote on your behalf
2. delegate your voting power to auto abstain
3. delegate your voting power to a vote of on-confidence

```
# COLD: Generate your vote delegation certificate using one of the 3 options:
scripts/address.sh generate_stake_vote_cert drep <drepId>
scripts/address.sh generate_stake_vote_cert script <scriptHash>
scripts/address.sh generate_stake_vote_cert abstain
scripts/address.sh generate_stake_vote_cert no-confidence

# PRODUCER: Build the tx.raw with the $DELE_VOTE_CERT
scripts/tx.sh stake_vote_reg_raw

# COPY: tx.raw to your cold node 
# COLD: Sign the withdraw transaction tx.raw
scripts/tx.sh stake_reg_sign

# COPY: tx.signed to your producer node
# PRODUCER: Submit the signed transaction 
scripts/tx.sh submit
```

### Withdrawing stake pool rewards

```
# PRODUCER: build you pool cert raw transaction
scripts/tx.sh pool_withdraw_raw

# COPY: tx.raw to your cold node 
# COLD: Sign the withdraw transaction tx.raw
scripts/tx.sh stake_reg_sign

# COPY: tx.signed to your producer node
# PRODUCER: Submit the signed transaction 
scripts/tx.sh submit
```

### Vote on a governance action as a SPO

Running a Stake Pool requires participation in Cardano governance. From _time to time_ you will need to cast your SPO vote for various governance actions.

```
# PRODUCER: Query the govern action id then build the vote
scripts/govern.sh action <govActionId>

# COLD: cast your vote on your cold machine
scripts/govern.sh vote <govActionId> <govActionIndex> <'yes' | 'no' | 'abstain'>

# COPY: vote.raw to your producer node
# PRODUCER: build the raw transaction with vote.raw as input 
scripts/tx.sh vote_raw

# COPY: tx.raw to your cold node 
# COLD: Sign the vote transaction tx.raw
scripts/tx.sh vote_sign

# COPY: tx.signed to your producer node
# PRODUCER: Submit the signed transaction 
scripts/tx.sh submit
```

---

## Registering a DRep

To register a stake pool you must have a running **fully synced** node. We can then generate the following assets:

<details>
<summary>DRep assets</summary>

<table>
    <tbody>
        <tr>
            <td>
                <p><code>drep.vkey</code></p>
            </td>
            <td>
                <p>DRep verification key</p>
            </td>
        </tr>
        <tr>
            <td>
                <p><code>drep.skey</code></p>
            </td>
            <td>
                <p>DRep signing key</p>
            </td>
        </tr>
        <tr>
            <td>
                <p><code>drep.cert</code></p>
            </td>
            <td>
                <p>DRep certificate</p>
            </td>
        </tr>
        <tr>
            <td>
                <p><code>drep.id</code></p>
            </td>
            <td>
                <p>DRep ID</p>
            </td>
        </tr>
    </tbody>
</table>
</details>

### Generate DRep keys and certificate

Start your DRep registration by generating keys and a DRep certificate.

```
# PRODUCER: Generate DRep keys and ID
scripts/govern.sh drep_keys
scripts/govern.sh drep_id 

# PRODUCER: Generate the DRep registration certificate assuming oyu have a public metadata URL
scripts/govern.sh drep_cert <url> 

# PRODUCER: Build a transaction with the drep certificate
scripts/tx.sh drep_reg_raw

# COPY: tx.raw to your cold node
# COLD: Sign the transaction
scripts/tx.sh drep_reg_sign

# COPY: tx.signed to your producer node
# PRODUCER: Submit the transaction
scripts/tx/submit.sh
```

### Vote on a governance action as a DRep

Being a DRep requires participation in Cardano governance. From _time to time_ you will need to cast your DRep vote for various governance actions.

```
# PRODUCER: Query the govern action id then build the vote
scripts/govern.sh action <govActionId>

# COLD: cast your vote on your cold machine - to vote as a DRep ensure you pass the last param: 'drep'
scripts/govern.sh vote <govActionId> <govActionIndex> <'yes' | 'no' | 'abstain'> drep

# COPY: vote.raw to your producer node
# PRODUCER: build the raw transaction with vote.raw as input 
scripts/tx.sh vote_raw

# COPY: tx.raw to your cold node 
# COLD: Sign the vote transaction tx.raw
scripts/tx.sh vote_sign

# COPY: tx.signed to your producer node
# PRODUCER: Submit the signed transaction 
scripts/tx.sh submit
```

---

## Repository info

### Contributors

* Upstream SPO - @upstream_ada
* Devhalls - @devhalls
* Grafana dashboard and leader slot query initially used from https://github.com/sanskys/SNSKY

### Contributing

Contributions are what make the open source community such an amazing place to learn, inspire, and create. Any contributions you make are greatly appreciated.

If you have a suggestion that would make this plugin better, please fork the repo and create a pull request. You can also simply open an issue with the tag "enhancement". Don't forget to give the project a star! Thanks again!

1. Fork the Project
2. Create your Feature Branch (git checkout -b feature/AmazingFeature)
3. Commit your Changes (git commit -m 'Add some AmazingFeature')
4. Push to the Branch (git push origin feature/AmazingFeature)
5. Open a Pull Request

[#BuildingTogether](https://x.com/search?q=buildingtogether)

### License

Distributed under the GPL-3.0 License. See LICENSE.txt for more information.

### Links

- [Cardano testnet faucet](https://docs.cardano.org/cardano-testnets/tools/faucet/)
- [Upstream SPO website](https://upstream.org.uk)
- [Upstream Twitter](https://x.com/Upstream_ada)

