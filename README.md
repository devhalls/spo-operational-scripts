Cardano SPO scripts

Developed by @devhalls

A collection of scripts and procedures for operating nodes on the avaibale CArdano networks.
Linux - Ubuntu

Assumptions

1. Your user is configured to your environments needs 

Setup
1. Edit the env replacing

# Configure your VPN connection

https://airvpn.org/linux/eddie/

```
curl -fsSL https://eddie.website/repository/keys/eddie_maintainer_gpg.key | sudo tee /usr/share/keyrings/eddie.website-keyring.asc > /dev/null

echo "deb [signed-by=/usr/share/keyrings/eddie.website-keyring.asc] http://eddie.website/repository/apt stable main" | sudo tee /etc/apt/sources.list.d/eddie.website.list

sudo apt update

sudo apt install eddie-cli

```



# Create fixed IP address on LAN network

```
# Install dependencies
sudo apt-get install net-tools

# Note the current network adapter name e.g. eth0 | wlo1
ip a

# Note the subnet mask (netmask) and host IP range
ifconfig -a
// Producer > 192.168.1.180 > 192.168.1.254 >>>> 255.255.255.0
// Relay > 192.168.1.243 > 192.168.1.254 >>>> 255.255.255.0

# Edit the network configs
cd /etc/netplan
sudo nano 50-cloud-init.yaml

network:
    ethernets:
        enp86s0:
            dhcp4: true
    version: 2
    wifis:
        wlo1:
            access-points:
                EE-56C2WP:
                    password: pabrf6T6EGmYLu
            dhcp4: false
            addresses:
                - 192.168.1.180/24
            routes:
                - to: default
                  via: 192.168.1.254
            nameservers:
                addresses:
                  - 8.8.8.8
                  - 8.8.4.4

# Test the restart and apply if you have no errors
sudo netplan try
```
