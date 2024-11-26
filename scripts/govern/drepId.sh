#!/bin/bash
# Usage: scripts/govern/drepId.sh <?format>
#
# Info:
#
#   - Get the DRep id
#   - Format can be 'hex' or 'bech32'

source "$(dirname "$0")/../../env"
source "$(dirname "$0")/../common.sh"
format=${1:-'bech32'}

$CNCLI conway governance drep id \
  --drep-verification-key-file $DREP_VKEY \
  --output-format $format \
  --out-file $DREP_ID
