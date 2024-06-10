#!/bin/bash

contentKey=${1:-0}
argCount=${2:-0}
actualCount=$((argCount+2))
blue='\033[0;34m'
orange='\033[0;33m'
red='\033[0;31m'
nc='\033[0m'

help_arr=()
argDir=()
helpPath="$(dirname "$0")/../metadata/help.txt"
argPath="$(dirname "$0")/../metadata/args.txt"

# Build arrays from the help files.
while IFS= read -r line || [[ "$line" ]]; do
  help_arr+=("$line")
done < $helpPath

while IFS= read -r line || [[ "$line" ]]; do
  argDir+=("$line")
done < $argPath

# Echo the help content.
display_help() {
  echo -e "$blue\nHelp:$nc"
  echo -e "$orange${help_arr[$contentKey]}$nc"
}

# Echo the usage content.
display_usage() {
  echo -e "$blue\nUsage:$nc"
  echo -e "${orange}cd \$NODE_HOME"
  echo -e "$orange${argDir[$contentKey]}$nc"
}

# If requesting help, just display help content
if [[ ( ${3} == "--help") ||  ${3} == "-h" || ( ${1} == "--help") ||  ${1} == "-h" ]]; then
  display_help
  display_usage
  echo -e ""
  exit 1
else
  if [  $# != $actualCount ]; then
    echo -e "$red\nUnexpected args count!"
    display_usage
    echo -e ""
    exit 1
  fi
fi
