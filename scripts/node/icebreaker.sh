#!/bin/bash
# Usage: node/icebreaker.sh (
#   download |
#   install |
#   run |
#   start |
#   stop |
#   restart |
#   watch |
#   status |
#   help [-h <BOOLEAN>]
# )
#
# Info:
#
#   - download) Download the icebreaker binaries and run the init installation. Note this setup currently allows for a single binary used by all networks.
#   - install) Install the icebreaker service.
#   - run) Run the icebreaker service.
#   - start) Starts the icebreaker service.
#   - stop) Stops the icebreaker service.
#   - restart) Restarts the icebreaker service.
#   - watch) Watch icebreaker service logs.
#   - status) Display icebreaker service status.
#   - help) View this files help. Default value if no option is passed.

source "$(dirname "$0")/../common.sh"

icebreaker_download() {
    exit_if_not_relay
    print 'ICEBREAKER' "Downloading icebreaker binaries"
    curl -fsSL \
         https://github.com/blockfrost/blockfrost-platform/releases/latest/download/curl-bash-install.sh \
         | bash

    source "$HOME/.local/opt/blockfrost-platform/add-to-path.sh"
    blockfrost-platform --init
}

icebreaker_install() {
    exit_if_not_relay
    print 'ICEBREAKER' "Creating icebreaker service: $ICEBREAKER_SERVICE"
    cp -p services/$ICEBREAKER_NAME.service services/$ICEBREAKER_SERVICE.temp
    sed -i services/$ICEBREAKER_SERVICE.temp \
        -e "s|NODE_USER|$NODE_USER|g" \
        -e "s|NODE_HOME|$NODE_HOME|g" \
        -e "s|ICEBREAKER_NAME|$ICEBREAKER_NAME|g" \
        -e "s|ICEBREAKER_SERVICE|$ICEBREAKER_SERVICE|g"
    sudo cp -p services/$ICEBREAKER_SERVICE.temp $SERVICE_PATH/$ICEBREAKER_SERVICE
    sudo systemctl daemon-reload
    sudo systemctl enable $ICEBREAKER_SERVICE
    sudo systemctl start $ICEBREAKER_SERVICE
    rm services/$ICEBREAKER_SERVICE.temp
    print 'ICEBREAKER' "Icebreaker service created: $ICEBREAKER_SERVICE" $green
    return 0
}

icebreaker_run() {
    $BLOCKFROST --network $NODE_NETWORK \
       --node-socket-path $NETWORK_SOCKET_PATH \
       --secret $ICEBREAKER_SECRET \
       --reward-address $ICEBREAKER_REWARD_ADDR
}

icebreaker_start() {
    exit_if_not_relay
    sudo systemctl start $ICEBREAKER_SERVICE
    print 'ICEBREAKER' "Mithril service started" $green
}

icebreaker_stop() {
    exit_if_not_relay
    sudo systemctl stop $ICEBREAKER_SERVICE
    print 'ICEBREAKER' "Mithril service stopped" $green
}

icebreaker_restart() {
    exit_if_not_relay
    sudo systemctl restart $ICEBREAKER_SERVICE
    print 'ICEBREAKER' "Mithril service restarted" $green
}

icebreaker_watch() {
    exit_if_cold
    journalctl -u $ICEBREAKER_SERVICE -f -o cat
}

icebreaker_status() {
    exit_if_not_relay
    sudo systemctl status $ICEBREAKER_SERVICE
}

case $1 in
    download) icebreaker_download ;;
    install) icebreaker_install ;;
    run) icebreaker_run ;;
    start) icebreaker_start ;;
    stop) icebreaker_stop ;;
    restart) icebreaker_restart ;;
    watch) icebreaker_watch ;;
    status) icebreaker_status ;;
    help) help "${2:-"--help"}" ;;
    *) help "${2:-"--help"}" ;;
esac
