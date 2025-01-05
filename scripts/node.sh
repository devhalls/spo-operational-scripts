#!/bin/bash
# Usage: node.sh [
#   install [...params] |
#   update [...params] |
#   mithril [...params] |
#   run |
#   start |
#   stop |
#   restart |
#   watch |
#   status |
#   view |
#   restart_prom |
#   watch_prom |
#   status_prom |
#   watch_prom_ex |
#   status_prom_ex |
#   restart_grafana |
#   watch_grafana |
#   status_grafana |
#   help [?-h]
# ]
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
#   - status) Display the node service status.
#   - view) View the node using gLiveView script.
#   - restart_prom) Restart the prometheus services.
#   - watch_prom) Watch the prometheus service logs.
#   - status_prom) Display the prometheus service status.
#   - watch_prom_ex) Watch the prometheus exporter service logs.
#   - status_prom_ex) Display the prometheus exporter service status.
#   - restart_grafana) Restart the grafana server services.
#   - watch_grafana) Watch the grafana server service logs.
#   - status_grafana) Display the grafana server service status.
#   - help) View this files help. Default value if no option is passed.

source "$(dirname "$0")/../env"
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
  exit_if_cold
  sudo systemctl status $NETWORK_SERVICE
}

node_view() {
  exit_if_cold
  bash $NETWORK_PATH/scripts/gLiveView.sh "$@"
}

node_restart_prom() {
  exit_if_cold
  sudo systemctl restart prometheus.service
  sudo systemctl restart prometheus-node-exporter.service
  print 'NODE' "Prometheus services restarted" $green
}

node_watch_prom() {
  exit_if_not_relay
  journalctl --system -u prometheus.service --follow
}

node_status_prom() {
  exit_if_not_relay
  sudo systemctl status prometheus.service
}

node_watch_prom_ex() {
  exit_if_cold
  journalctl --system -u prometheus-node-exporter.service --follow
}

node_status_prom_ex() {
  exit_if_cold
  sudo systemctl status prometheus-node-exporter.service
}

node_restart_grafana() {
  exit_if_not_relay
  sudo systemctl restart grafana-server.service
  print 'NODE' "Grafana service restarted" $green
}

node_watch_grafana() {
  exit_if_not_relay
  journalctl --system -u grafana-server.service --follow
}

node_status_grafana() {
  exit_if_not_relay
  sudo systemctl status grafana-server.service
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
