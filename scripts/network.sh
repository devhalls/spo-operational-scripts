#!/bin/bash
# Usage: network.sh (
#   ngrok |
#   set_ip [ <STRING>] |
#   help [-h <STRING>]
# )
#
# Info:
#
#   - ngrok) Install and setup an ngrok TCP service.
#   - set_ip) Set a fixed IP address for the devices default network interface.
#   - help) View this files help. Default value if no option is passed.

source "$(dirname "$0")/common.sh"

network_ngrok_install() {
    exit_if_cold
    servicesDir="$(dirname "$0")/../services"

    curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc |
        sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null &&
        echo "deb https://ngrok-agent.s3.amazonaws.com buster main" |
        sudo tee /etc/apt/sources.list.d/ngrok.list &&
        sudo apt install ngrok

    cp -p $servicesDir/ngrok.service $servicesDir/$NGROK_SERVICE.temp
    sed -i $servicesDir/$NGROK_SERVICE.temp \
        -e "s|NODE_USER|$NODE_USER|g" \
        -e "s|NGROK_EDGE|$NGROK_EDGE|g" \
        -e "s|NODE_PORT|$NODE_PORT|g"
    sudo cp -p $servicesDir/$NGROK_SERVICE.temp $SERVICE_PATH/$NGROK_SERVICE

    rm $servicesDir/$NGROK_SERVICE.temp
    ngrok config add-authtoken $NGROK_TOKEN
    sudo systemctl daemon-reload
    sudo systemctl enable $NGROK_SERVICE
    sudo systemctl start $NGROK_SERVICE
    print 'NETWORK' "Ngrok installed for edge $NGROK_EDGE" $green
}

network_set_ip() {
    print 'NETWORK' 'Setting fixed IP address for your device'
    sudo $PACKAGER install net-tools -y

    ipAddress=${1:-$(hostname -I | awk '{print $1}')}
    router=$(ip r | grep -m 1 default | awk '{print $3}')
    interface=$(route | grep -m 1 '^default' | grep -o '[^ ]*$')

    update_or_append "/etc/dhcpcd.conf" "# Added by node scripts" "# Added by node scripts"
    update_or_append "/etc/dhcpcd.conf" "interface" "interface $interface"
    update_or_append "/etc/dhcpcd.conf" "static ip_address" "static ip_address=$ipAddress/24"
    update_or_append "/etc/dhcpcd.conf" "static routers" "static routers=$router"
    update_or_append "/etc/dhcpcd.conf" "static domain_name_servers" "static domain_name_servers=$router"
    sudo systemctl status systemd-networkd

    print 'NETWORK' "IP address set to $ipAddress. Restart your device for this change to take effect." $green
}

case $1 in
    ngrok) network_ngrok_install ;;
    set_ip) network_set_ip ;;
    help) help "${2:-"--help"}" ;;
    *) help "${1:-"--help"}" ;;
esac
