#!/bin/bash
# Usage: node.sh (
#   install [...params] |
#   update [...params] |
#   mithril [...params] |
#   run |
#   start |
#   stop |
#   restart |
#   watch |
#   status |
#   view [...params] |
#   version |
#   restart_prom |
#   watch_prom |
#   status_prom |
#   watch_prom_ex |
#   status_prom_ex |
#   restart_grafana |
#   watch_grafana |
#   status_grafana |
#   help [-h <BOOLEAN>]
# )
#
# Info:
#
#   - install) Installs a Cardano node and all dependencies. Pass additional params to this command to call specific install functions.
#   - update) Updates the current node version. Pass additional params to this command to call specific install functions.
#   - mithril) Download binaries and sync your node. Pass additional params to this command to call specific install functions.
#   - run) Run the cardano node based on the $NODE_TYPE.
#   - start) Start the node systemctl service.
#   - stop) Stop the node systemctl service.
#   - restart) Restart the node systemctl service.
#   - watch) Watch the node service logs.
#   - status) Display the node status overview, services and ports view.
#   - view) View the node using gLiveView script.
#   - version) View the installed $CNNODE version.
#   - restart_prom) Restart the prometheus services.
#   - watch_prom) Watch the prometheus service logs.
#   - status_prom) Display the prometheus service status.
#   - watch_prom_ex) Watch the prometheus exporter service logs.
#   - status_prom_ex) Display the prometheus exporter service status.
#   - restart_grafana) Restart the grafana server services.
#   - watch_grafana) Watch the grafana server service logs.
#   - status_grafana) Display the grafana server service status.
#   - help) View this files help. Default value if no option is passed.

source "$(dirname "$0")/common.sh"

node_run() {
    if [ "${NODE_TYPE}" == "relay" ]; then
        print 'NODE' "Node starting as ${NODE_TYPE}"
        ${CNNODE} run --topology ${TOPOLOGY_PATH} \
            --database-path ${NETWORK_DB_PATH} \
            --socket-path ${NETWORK_SOCKET_PATH} \
            --host-addr ${NODE_HOSTADDR} \
            --port ${NODE_PORT} \
            --config ${CONFIG_PATH}
    elif [ "${NODE_TYPE}" == "producer" ]; then
        print 'NODE' "Node starting as ${NODE_TYPE}"
        ${CNNODE} run --topology ${TOPOLOGY_PATH} \
            --database-path ${NETWORK_DB_PATH} \
            --socket-path ${NETWORK_SOCKET_PATH} \
            --host-addr ${NODE_HOSTADDR} \
            --port ${NODE_PORT} \
            --config ${CONFIG_PATH} \
            --shelley-kes-key ${KES_KEY} \
            --shelley-vrf-key ${VRF_KEY} \
            --shelley-operational-certificate ${NODE_CERT}
    else
        print 'ERROR' "Node cannot run as ${NODE_TYPE}" $red
    fi
}

node_start() {
    exit_if_cold
    sudo systemctl start $NETWORK_SERVICE
    print 'NODE' "Node service started" $green
}

node_stop() {
    exit_if_cold
    sudo systemctl stop $NETWORK_SERVICE
    print 'NODE' "Node service stopped" $green
}

node_restart() {
    exit_if_cold
    sudo systemctl restart $NETWORK_SERVICE
    print 'NODE' "Node service restarted" $green
}

node_watch() {
    exit_if_cold
    journalctl -u $NETWORK_SERVICE -f -o cat
}

node_status() {
    # Default view
    local selected="Services"
    local counter=1

    # Process and display output every x second(s)
    while true; do
        # Clear screen
        tput cup 0 0
        printf "\e[2J"

        # Render the display title
        echo -e "\n${orange}UPSTREAM Stake Pool - ${selected}${nc} ($NODE_NETWORK:$NODE_TYPE)\n"

        # Render the display based on selected view
        case $selected in

            # 1. Process overview view
            Overview)
                # Prepare the node port state
                local portState
                if ss -tuln | grep -q ":$NODE_PORT"; then
                  portState="${green}open${nc}"
                else
                  portState="${red}closed${nc}"
                fi

                # Prepare the node version string
                local nodeVersion=$(node_version)
                if [[ -n "$nodeVersion" ]]; then
                  nodeVersion="Active: $green$nodeVersion$nc"
                else
                  nodeVersion="${red}Inactive${nc}"
                fi

                # Prepare the array of table rows
                local overviewRows=(
                    "$(echo -e "$green+$nc $red-$nc | NAME | VALUE | DETAIL")"
                    "$(print_state "yes" "Network | $orange$NODE_NETWORK$nc | Type: $green$NODE_TYPE$nc")"
                    "$(print_state "yes" "Node Version | $orange$NODE_VERSION$nc | $nodeVersion")"
                    "$(print_state "yes" "Node Port | $orange$NODE_PORT$nc | State: $portState")"
                    "$(print_state "yes" "Node Directory | $orange$NODE_HOME$nc | State: ${green}Installed${nc}")"
                )

                # Display overview table output
                print_table "${overviewRows[@]}"
                ;;

            # 2. Process services view
            Services)
                # Prepare the extended data file check
                local promNodeVersionExists
                local promNodeVersionOutput
                local prodDataPath=$NETWORK_PATH/stats/data-pool.prom
                if [[ -f "$prodDataPath" ]] && grep -q "data_nodeVersion" "$prodDataPath"; then
                    promNodeVersionExists="yes"
                    promNodeVersionOutput="${green}$prodDataPath contains data_nodeVersion${nc} | ${green}required${nc}"
                else
                    promNodeVersionExists=""
                    promNodeVersionOutput="${red}$prodDataPath${nc} | ${red}required${nc}"
                fi

                # Prepare DBSync and postgres checks
                local dbSyncOutput
                local dbSyncBlock=$($(dirname "$0")/dbsync.sh get_block)
                if [[ -n "$dbSyncBlock" ]]; then
                    dbSyncOutput="${green}DBSync database ${POSTGRES_DB}, latest block: ${dbSyncBlock}${nc} | ${green}-${nc}"
                else
                    dbSyncOutput="${red}DBSync database not reachable ${POSTGRES_DB}${nc} | ${red}-${nc}"
                fi

                # Prepare the arrays to pass to table output
                local serviceRows=(
                    "$(echo -e "$green+$nc $red-$nc | NAME | RESULT | ?")"
                    "$(print_service_state $NETWORK_SERVICE "Cardano Node")"
                    "$(print_service_state $MITHRIL_SERVICE "Mithril Signer")"
                    "$(print_service_state $MITHRIL_SQUID_SERVICE "Mithril Squid Proxy")"
                    "$(print_service_state $DB_SYNC_SERVICE "DBSync Service")"
                    "$(print_state "$dbSyncBlock" "DBSync Database | $dbSyncOutput")"
                    "$(print_service_state $PROMETHEUS_EXPORTER_SERVICE "Prometheus Exporter")"
                    "$(print_crontab_state "$NODE_HOME/scripts/pool.sh get_stats" "Crontab get_stats()")"
                    "$(print_state "$promNodeVersionExists" "Crontab get_stats() Output | $promNodeVersionOutput")"
                    "$(print_service_state $PROMETHEUS_SCRAPER_SERVICE "Prometheus Scraper")"
                    "$(print_service_state $GRAFANA_SERVICE "Grafana Dashboard")"
                    "$(print_service_state $NGROK_SERVICE "Ngrok Networking")"
                )

                # Display service table output
                print_table "${serviceRows[@]}"
                ;;

            # 3. Process ports view
            Ports)
                # Read and prepare port data
                local portInfo=$(sudo ss -tuln | awk '
                    NR == 1 { next }
                    {
                        proto = ($0 ~ /^tcp/) ? "tcp" : ($0 ~ /^udp/) ? "udp" : "?"
                        split($5, parts, ":")
                        port = parts[length(parts)]
                        sub(":" port "$", "", $5)
                        printf "%-7s | %-16s | %-5s | %s\n", $2, $5, port, proto
                    }')
                IFS=$'\n' read -r -d '' -a portRows <<< "$portInfo"$'\0'
                declare -A portConfigs=(
                    ["0.0.0.0:6000"]="Cardano Node"
                    ["0.0.0.0:12798"]="Cardano UI"
                    ["127.0.0.1:12788"]="Cardano EKG"
                    ["0.0.0.0:9091"]="Prometheus exporter"
                    ["0.0.0.0:9100"]="Prometheus Exporter"
                    ["*:9100"]="Prometheus Exporter"
                    ["0.0.0.0:22"]="SSH"
                    ["*:22"]="SSH"
                )
                for i in "${!portRows[@]}"; do
                    IFS='|' read -r state ip port proto <<< "${portRows[$i]}"
                    state=$(echo "$state" | xargs)
                    ip=$(echo "$ip" | xargs)
                    port=$(echo "$port" | xargs)
                    proto=$(echo "$proto" | xargs)
                    key="$ip:$port"
                    if [[ -n "${portConfigs["$key"]}" ]]; then
                        label="${green}${portConfigs["$key"]}${nc}"
                    else
                        label="?"
                    fi
                    portRows[$i]=$(echo -e "${portRows[$i]} | ${label}")
                done

                # Display port table output
                print_table "${portRows[@]}"
                ;;

            # 4. Process keys view
            Keys)
                # Display keys output
                $(dirname "$0")/query.sh keys
                ;;
        esac

        # Display actions
        echo -e "\no = ${orange}Overview${nc} | s = ${orange}Services${nc} | p = ${orange}Ports${nc} | k = ${orange}Keys${nc}"
        echo -e "q = ${orange}Quit${nc}"
        echo -e "\nRefresh count: ${orange}${counter}${nc}"

        # Wait for single key input
        read -rsn1 key
        # If key is escape (e.g. first char of arrow), read the next two silently
        if [[ "$key" == $'\e' ]]; then
          read -rsn2 -t 0.01 discard # Consume the rest of the key sequence
          continue # Ignore it
        fi
        # Set the selected view
        case "$key" in
            o|O) selected="Overview" ;;
            s|S) selected="Services" ;;
            p|P) selected="Ports" ;;
            k|K) selected="Keys" ;;
            a|A) selected="All" ;;
            q|Q) break ;;
        esac

        # Sleep then loop
        sleep 0.2
        ((counter++))
    done

    # Cleanup
    tput cnorm
    stty sane
    clear
}

node_view() {
    exit_if_cold
    bash $NETWORK_PATH/scripts/gLiveView.sh "$@"
}

node_version() {
    echo "$($CNNODE --version)" | grep -oP 'cardano-node \K[0-9]+(\.[0-9]+)*'
}

node_restart_prom() {
    exit_if_cold
    sudo systemctl restart $PROMETHEUS_EXPORTER_SERVICE
    sudo systemctl restart $PROMETHEUS_SCRAPER_SERVICE
    print 'NODE' "Prometheus services restarted" $green
}

node_watch_prom() {
    exit_if_not_relay
    journalctl --system -u $PROMETHEUS_SCRAPER_SERVICE --follow
}

node_status_prom() {
    exit_if_not_relay
    sudo systemctl status $PROMETHEUS_SCRAPER_SERVICE
}

node_watch_prom_ex() {
    exit_if_cold
    journalctl --system -u $PROMETHEUS_EXPORTER_SERVICE --follow
}

node_status_prom_ex() {
    exit_if_cold
    sudo systemctl status $PROMETHEUS_EXPORTER_SERVICE
}

node_restart_grafana() {
    exit_if_not_relay
    sudo systemctl restart $GRAFANA_SERVICE
    print 'NODE' "Grafana service restarted" $green
}

node_watch_grafana() {
    exit_if_not_relay
    journalctl --system -u $GRAFANA_SERVICE --follow
}

node_status_grafana() {
    exit_if_not_relay
    sudo systemctl status $GRAFANA_SERVICE
}

case $1 in
    install) bash $(dirname "$0")/node/install.sh "${@:2}" ;;
    update) bash $(dirname "$0")/node/update.sh "${@:2}" ;;
    mithril) bash $(dirname "$0")/node/mithril.sh "${@:2}" ;;
    run) node_run ;;
    start) node_start ;;
    stop) node_stop ;;
    restart) node_restart ;;
    watch) node_watch ;;
    status) node_status ;;
    view) node_view "${@:2}" ;;
    version) node_version ;;
    restart_prom) node_restart_prom ;;
    watch_prom) node_watch_prom ;;
    status_prom) node_status_prom ;;
    watch_prom_ex) node_watch_prom_ex ;;
    status_prom_ex) node_status_prom_ex ;;
    restart_grafana) node_restart_grafana ;;
    watch_grafana) node_watch_grafana ;;
    status_grafana) node_status_grafana ;;
    help) help "${2:-"--help"}" ;;
    *) help "${1:-"--help"}" ;;
esac
