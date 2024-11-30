#!/bin/bash

blue='\033[0;34m'
orange='\033[0;33m'
green='\033[0;32m'
red='\033[0;31m'
nc='\033[0m'

if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
  echo -e $orange
  sed -ne '/^#/!q;s/^#$/# /;/^# /s/^# //p' < "$0" |
    awk -v f="${1#-h}" '!f && /^Usage:/ || u { u=!/^\s*$/; if (!u) exit } u || f'
  echo -e $nc
  exit 1
fi

print() {
  label=${1:-'LABEL'}
  message=${2:-'Message'}
  color=${3:-$orange}
  echo -e "$color[$label] $message$nc"
}

exitIfDeclined() {
  read -p "$1 ([y]es or [N]o): "
  case $(echo $REPLY | tr '[A-Z]' '[a-z]') in
    y|yes) echo "yes" ;;
    *)     exit 1 ;;
  esac
}

exitIfNotCold() {
  if [[ $NODE_TYPE != 'cold' && $NODE_NETWORK == 'mainnet' ]]; then
    print "ERROR" "this command can only be run on a cold device" $red
    exit 1;
  fi;
}
