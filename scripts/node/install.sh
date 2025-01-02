#!/bin/bash
# Usage: node/install.sh [
#   install |
#   validate |
#   dependencies |
#   binaries |
#   build [...params] |
#   download [...params] |
#   configs |
#   guild |
#   prometheus_explorer [?monitoringIp] |
#   grafana |
#   service |
#   clean |
#   help [?-h]
# ]
#
# Info:
#
#   - install) Installs a Cardano node and all dependencies. Default value if no options are passed.
#   - validate) Validate if an installation can run.
#   - dependencies) Install package dependencies and node directories.
#   - binaries) Build or download the node binaries based on $NODE_BUILD.
#   - build) Build the node binaries from source.
#   - download) Download the node binaries.
#   - configs) Download the node config files.
#   - guild) Download the guild gLiveView script.
#   - prometheus_explorer) Install Prometheus node exporter on the block producers and all relays. The monitoringIp is only used for producer nodes.
#   - grafana) Install Grafana on Monitoring Node only - must be a relay.
#   - service) Create the node systemctl service.
#   - clean) Clean the installation and remove all files.
#   - help) View this files help.

source "$(dirname "$0")/../../env"
source "$(dirname "$0")/../common.sh"

install_validate() {
  print 'INSTALL' 'Validating installation'
  if [ ! -f "$(dirname "$0")/../../env" ]; then
    print 'ERROR' 'No env file found, please review the README.md' $red
    exit 1
  fi
  if [ -d "$NETWORK_PATH" ]; then
    print 'ERROR' 'Already installed, remove your current installation to reinstall' $red
    exit 1
  fi
  print 'INSTALL' 'Install validation passed' $green
  return 0
}

install_dependencies() {
  print 'INSTALL' 'Installing dependencies and creating directories'
  sudo $PACKAGER install jq bc tcptraceroute supervisor wget curl -y
  if [ $? -ne 0 ]; then
    print 'INSTALL' 'Could not install packages' $red
    exit 1
  fi
  mkdir -p $NETWORK_PATH \
    $NETWORK_PATH/temp \
    $NETWORK_PATH/keys \
    $NETWORK_PATH/scripts \
    $NETWORK_PATH/logs \
    $NETWORK_PATH/stats \
    $BIN_PATH
  print 'INSTALL' 'Dependencies installed' $green
  return 0
}

install_binaries() {
  exit_if_cold
  if [[ $NODE_BUILD == 1 ]]; then
    bash $(dirname "$0")/download.sh download || install_failed
  elif [[ $NODE_BUILD == 2 ]]; then
    bash $(dirname "$0")/build.sh build || install_failed
  else
    print 'INSTALL' 'Node binaries skipped' $green
    return 0
  fi
}

install_configs() {
  exit_if_cold
  print 'INSTALL' "Downloading config files for $NODE_NETWORK"
  for C in ${CONFIG_DOWNLOADS[@]}; do
    wget -O $NETWORK_PATH/$C $CONFIG_REMOTE/$C
    if [ $? -ne 0 ]; then
      print 'ERROR' "Could not download config: $C" $red
      exit 1
    fi
  done
  print 'INSTALL' "Downloaded configs for $NODE_NETWORK" $green
  return 0
}

install_guild() {
  exit_if_cold
  print 'INSTALL' "Downloading guild scripts"
  for G in ${GUILD_SCRIPT_DOWNLOADS[@]}; do
      wget -O $NETWORK_PATH/scripts/$G $GUILD_REMOTE/$G
      if [ $? -ne 0 ]; then
        print 'ERROR' "Could not download config: $G" $red
        exit 1
      fi
  done
  chmod +x $NETWORK_PATH/scripts/gLiveView.sh
  sed -i $NETWORK_PATH/scripts/env \
      -e "s|\#CONFIG=\"\${CNODE_HOME}\/files\/config.json\"|CONFIG=\"${NETWORK_PATH}\/config.json\"|g" \
      -e "s|\#SOCKET=\"\${CNODE_HOME}\/sockets\/node.socket\"|SOCKET=\"${NETWORK_PATH}\/db\/socket\"|g" \
      -e "s|\#CNODE_PORT=6000|CNODE_PORT=\"${NODE_PORT}\"|g" \
      -e "s|\#CNODEBIN=\"\${HOME}\/.local\/bin\/cardano-node\"|CNODEBIN=\"\${HOME}\/local\/bin\/cardano-node\"|g" \
      -e "s|\#CCLI=\"\${HOME}\/.local\/bin\/cardano-cli\"|CCLI=\"\${HOME}\/local\/bin\/cardano-cli\"|g"
  print 'INSTALL' "Downloaded guild scripts" $green
  return 0
}

install_prometheus_explorer() {
  exit_if_cold
  print 'INSTALL' 'Prometheus explorer'
  monitoringIp=${1}
  sudo $PACKAGER install -y prometheus-node-exporter
  sudo systemctl enable prometheus-node-exporter.service
  sed -i $CONFIG_PATH -e "s/127.0.0.1/0.0.0.0/g"
  sudo systemctl restart prometheus-node-exporter.service

  if [ $NODE_TYPE == 'producer' ] | [ $NODE_NETWORK == 'mainnet' ]; then
    if [ ! $monitoringIp ]; then
      print 'ERROR' 'Please supply your monitoring node IP address' $red
      exit 1
    fi
    sudo ufw allow proto tcp from $monitoringIp to any port 9100
    sudo ufw allow proto tcp from $monitoringIp to any port 12798
    sudo ufw reload
  fi
  print 'INSTALL' 'Prometheus explorer installed' $green
}

install_grafana() {
  exit_if_not_relay
  print 'INSTALL' 'Grafana dashboard'

  wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
  echo "deb https://packages.grafana.com/oss/deb stable main" > grafana.list
  sudo mv grafana.list /etc/apt/sources.list.d/grafana.list
  sudo $PACKAGER update && sudo $PACKAGER install -y prometheus grafana

  source ~/.bashrc
  sudo grafana-cli plugins install grafana-clock-panel
  sudo grafana-cli plugins install marcusolsson-csv-datasource

  # Adjust the prometheus service command
  serviceDir="$(dirname "$0")/../../services"
  sudo cp -p $serviceDir/prometheus.yml /etc/prometheus/prometheus.yml
  sudo sed -i "/^ExecStart=/c\\ExecStart=/usr/bin/prometheus-node-exporter --collector.textfile.directory=$NETWORK_PATH/stats --collector.textfile" /lib/systemd/system/prometheus-node-exporter.service

  # Edit grafana ini
  sudo sed -i "/# disable user signup \/ registration/{n;s/.*/allow_sign_up = false/}" "/etc/grafana/grafana.ini"
  if ! sudo grep -q "plugin.marcusolsson-csv-datasource" /etc/grafana/grafana.ini; then
    echo "[plugin.marcusolsson-csv-datasource]" | sudo tee -a /etc/grafana/grafana.ini > /dev/null
    echo "allow_local_mode = true" | sudo tee -a /etc/grafana/grafana.ini > /dev/null
  fi

  # Enable and restart the services
  sudo systemctl enable grafana-server.service
  sudo systemctl enable prometheus.service
  sudo systemctl enable prometheus-node-exporter.service
  sudo systemctl restart grafana-server.service
  sudo systemctl restart prometheus.service
  sudo systemctl restart prometheus-node-exporter.service
  print 'INSTALL' 'Grafana dashboard installed' $green
}

install_service() {
  print 'INSTALL' "Creating node service: $NETWORK_SERVICE"
  cp -p services/cardano-node.service services/$NETWORK_SERVICE.temp
  sed -i services/$NETWORK_SERVICE.temp \
      -e "s|NODE_NETWORK|$NODE_NETWORK|g" \
      -e "s|NODE_HOME|$NODE_HOME|g" \
      -e "s|NODE_USER|$NODE_USER|g" \
      -e "s|NETWORK_SERVICE|$NETWORK_SERVICE|g"
  sudo cp -p services/$NETWORK_SERVICE.temp $SERVICE_PATH/$NETWORK_SERVICE
  sudo systemctl daemon-reload
  sudo systemctl enable $NETWORK_SERVICE
  rm services/$NETWORK_SERVICE.temp
  print 'INSTALL' "Node service created: $NETWORK_SERVICE" $green
  return 0
}

install_clean() {
  confirm 'Are you sure?'
  rm -rf $NETWORK_PATH $BIN_PATH
  sudo rm -f $SERVICE_PATH/$NETWORK_SERVICE
  if [ $? -ne 0 ]; then
    print 'INSTALL' "Could not delete node files" $red
    exit 1
  fi
  print 'INSTALL' "Node files have been deleted" $green
  return 0
}

install_failed() {
  rm -rf $NETWORK_PATH $BIN_PATH
  exit 1
}

install() {
  install_validate
  install_dependencies
  install_binaries
  install_configs
  install_guild
  install_service
  $CNNODE --version
  $CNCLI --version
  print 'INSTALL' "Edit your topology config at $NETWORK_PATH/topology.json" $green
  return 0
}

case $1 in
  install) install ;;
  validate) install_validate ;;
  dependencies) install_dependencies ;;
  binaries) install_binaries ;;
  build) bash $(dirname "$0")/build.sh "${@:2}" ;;
  download) bash $(dirname "$0")/download.sh "${@:2}" ;;
  configs) install_configs ;;
  guild) install_guild ;;
  prometheus_explorer) install_prometheus_explorer ;;
  grafana) install_grafana ;;
  service) install_service ;;
  clean) install_clean ;;
  help) help "${2:-"--help"}" ;;
  *) install ;;
esac
