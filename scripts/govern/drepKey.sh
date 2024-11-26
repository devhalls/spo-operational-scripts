#!/bin/bash
# Usage: scripts/govern/drepKey.sh
#
# Info:
#
#   - Generate a pair of DRep keys

source "$(dirname "$0")/../../env"
source "$(dirname "$0")/../common.sh"

if [ -f $DREP_KEY ]; then
  print "DREP" "DRep keys already exists, delete the existing key to generate a new one" $red
  exit 1
fi

$CNCLI conway governance drep key-gen \
  --verification-key-file $DREP_VKEY \
  --signing-key-file $DREP_KEY
