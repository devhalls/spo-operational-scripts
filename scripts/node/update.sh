#!/bin/bash
# Usage: node/update.sh [
#   update |
#   latest |
#   current |
#   check |
#   binaries |
#   build [...params] |
#   download [...params] |
#   help [?-h]
# ]
#
# Info:
#
#   - update) Updates a cardano node to $NODE_VERSION. Default value if no options are passed.
#   - target) Get the target cardano node version from the env file.
#   - current) Get the current node version.
#   - check) Check if there is an update available from the current version.
#   - binaries) Build or download the node binaries based on $NODE_BUILD.
#   - build) Build the node binaries from source.
#   - download) Download the node binaries.
#   - help) View this files help.

source "$(dirname "$0")/../common.sh"

update_target_version() {
    echo $NODE_VERSION
}

update_current_version() {
    echo "$($CNNODE --version | awk '{print $2}')"
}

update_check_version() {
    latest=$(update_target_version)
    current=$(update_current_version)
    if [ "$current" == "$latest" ]; then
        print 'UPDATE' "Cardano node is already up to date (v$current)" $green
        exit 1
    elif [ -z "$current" ] || [ -z "$latest" ]; then
        print 'UPDATE' "Unable to read update versions [current:$current] [latest:$latest]" $red
        exit 1
    else
        echo $latest
    fi
}

update_binaries() {
    print 'UPDATE' 'Installing node binaries'
    if [[ $NODE_BUILD == 1 ]]; then
        bash $(dirname "$0")/download.sh download
    elif [[ $NODE_BUILD == 2 ]]; then
        bash $(dirname "$0")/build.sh build
    else
        print 'UPDATE' 'Node binaries skipped' $green
    fi
}

update() {
    latest=$(update_check_version)
    confirm "Please confirm update to the new version: $latest?"
    bash $(dirname "$0")/../node.sh stop
    update_binaries
    bash $(dirname "$0")/../node.sh restart
    source ~/.bashrc
    $CNNODE --version
    $CNCLI --version
    print 'UPDATE' "Node updated and restarted" $green
}

case $1 in
    update) update $@ ;;
    check) update_check_version ;;
    target) update_target_version ;;
    current) update_current_version ;;
    binaries) update_binaries ;;
    build) bash $(dirname "$0")/build.sh "${@:2}" ;;
    download) bash $(dirname "$0")/download.sh "${@:2}" ;;
    help) help "${2:-"--help"}" ;;
    *) update $@ ;;
esac
