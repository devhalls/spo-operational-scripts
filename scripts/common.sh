#!/bin/bash

# Define global variables

blue='\033[0;34m'
orange='\033[0;33m'
green='\033[0;32m'
red='\033[0;31m'
nc='\033[0m'

# Define global functions

help() {
  echo -e $orange
  sed -ne '/^#/!q;s/^#$/# /;/^# /s/^# //p' < "$0" |
    awk -v f="${1#-h}" '!f && /^Usage:/ || u { u=!/^\s*$/; if (!u) exit } u || f'
  echo -e $nc
  exit 1
}

print() {
  label=${1:-'LABEL'}
  message=${2:-'Message'}
  color=${3:-$orange}
  echo -e "$color[$label] $message$nc"
  if [ -f "$NETWORK_PATH/logs/script.log" ]; then
    echo -e "$color[$label] $message$nc" >> $NETWORK_PATH/logs/script.log
  fi
}

confirm() {
  read -p "$1 ([y]es or [N]o): "
  case $(echo $REPLY | tr '[A-Z]' '[a-z]') in
    y|yes) echo "yes" ;;
    *)     exit 1 ;;
  esac
}

platform() {
  OS=$(uname)
  if [[ "$OS" == "Linux" ]]; then
      echo "linux"
  elif [[ "$OS" == "Darwin" ]]; then
      echo "macos"
  elif [[ "$OS" == "MINGW"* || "$OS" == "CYGWIN"* ]]; then
      echo "windows"
  else
      echo "unknown"
  fi
}

platform_arm() {
  ARCH=$(uname -m)
  if [[ "$ARCH" == "arm"* || "$ARCH" == "aarch64" ]]; then
    echo "arm"
  fi
}

get_param() {
  echo "$1" | grep "^$2" | awk '{for(i=2; i<=NF; i++) printf "%s ", $i; print ""}'
}

get_option() {
  local option_name="$1"
  local option_value=""
  shift
  while [[ $# -gt 1 ]]; do
    case "$1" in
      "$option_name")
        option_value="$option_value $1 $2"
        shift 2 # move past the option and its value
        ;;
      *)
        shift  # unknown option
        ;;
    esac
  done
  echo "$option_value"
}

update_or_append() {
  file=${1}
  check=${2}
  line=${3}
  if grep -q "^$check" "$file"; then
    sudo sed -i "s|^$check.*|$line|" "$file"
  else
    echo "$line" | sudo tee -a $file > /dev/null
  fi
}

exit_if_invalid() {
  # Perform global checks
  if [[ -z $CNCLI ]]; then echo "cardano-cli command cannot be found, exiting..."; exit 127; fi
  if [[ -z $(which jq) ]]; then echo "jq command cannot be found, exiting..."; exit 127; fi
}

exit_if_file_missing() {
  if [ ! -f $1 ]; then
    print 'ERROR' "File $1 does not exist" $red
    exit 1
  fi
}

exit_if_cold() {
  if [[ $NODE_TYPE == 'cold' && $NODE_NETWORK == 'mainnet' ]]; then
    print "ERROR" "this command can not be run on a cold device" $red
    exit 1;
  fi;
}

exit_if_not_cold() {
  if [[ $NODE_TYPE != 'cold' && $NODE_NETWORK == 'mainnet' ]]; then
    print "ERROR" "this command can only be run on a cold device" $red
    exit 1;
  fi;
}

exit_if_not_producer() {
  if [[ $NODE_TYPE != 'producer' && $NODE_NETWORK == 'mainnet' ]]; then
    print "ERROR" "this command can only be run on a producer device" $red
    exit 1;
  fi;
}

exit_if_not_relay() {
  if [[ $NODE_TYPE != 'relay' && $NODE_NETWORK == 'mainnet' ]]; then
    print "ERROR" "this command can only be run on a relay device" $red
    exit 1;
  fi;
}
