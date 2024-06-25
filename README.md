#Cardano Stake Pool Operator (SPO) scripts

A collection of scripts and procedures for operating a stake pool on the various Cardano networks.

Developed by Upstream SPO [UPSTR](https://upstream.org.uk)

---

### Assumptions

1. Your OS, network and user are configured
2. Tested on Linux - Ubuntu
3. You are comfortable with cardano-node / cardano-cli and SPO requirements 
4. You are comfortable with Linux and managing networks and servers

---

### Setup

Create a directory, pull this repo and configure the env file.

```
mkdir Node && cd Node
git clone https://github.com/devhalls/spo-operational-scripts.git . 
cp -p env.example > env
nano env
```

Run the installation script

```
scripts/install.sh
```

Edit your typology

```
nano networks/mainnet/topology.json
```

Start your node

```
sudo systemctl start $NETWORK_SERVICE
```

---

### Road map

1. Update scripts at /gen, /mythril, /query and /tx implementation.
2. Detail notes for installation and build steps, you can read the scripts in the meantime to gain an understanding of the procedures.
3. Test multiple networks on single machine.
4. Detail OS dependencies.
5. Add useful networking / tunnel examples.
6. Add docker compose deployment.
