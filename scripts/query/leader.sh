#!/bin/bash
# Usage: scripts/query/leader.sh
#
# Info:
#
#   - Runs the pool leader slot check and creates file 'epoch.txt'

source "$(dirname "$0")/../../env"
source "$(dirname "$0")/../common.sh"

# Set runtime variables
period=${1:-next}
network=$NODE_NETWORK
network_magic=$NETWORK_ARG
if [[ ! -d "$NETWORK_PATH/logs" ]]; then mkdir $NETWORK_PATH/logs; fi
echo $$ > "$NETWORK_PATH/logs/leaderScheduleCheck.pid";

# Validate vrf.skey presence and byron-genesis.json
if [[ ! -f "$VRF_KEY" ]]; then print 'LEADER' "vrf.skey not found" $red; exit 127; fi
read -ra BYRON_GENESIS <<< "$(jq -r '[ .startTime, .protocolConsts.k, .blockVersionData.slotDuration ] |@tsv' < $NETWORK_PATH/byron-genesis.json)"
if [[ -z $BYRON_GENESIS ]]; then print 'LEADER' "BYRON GENESIS config file not loaded correctly" $red; exit 127; fi

# Check that node is synced
function isSynced(){
  isSynced=false
  sync_progress=$($CCLI query tip $network_magic --socket-path $NETWORK_SOCKET_PATH | jq -r ".syncProgress")
  if [[ $sync_progress == "100.00" ]]; then
      isSynced=true
  fi
  echo $isSynced
}

# Get current epoch
function getCurrentEpoch(){
  echo $($CCLI query tip $network_magic --socket-path $NETWORK_SOCKET_PATH | jq -r ".epoch")
}

# Get epoch start time based on current one
function getEpochStartTime(){
  byron_genesis_start_time=${BYRON_GENESIS[0]}
  byron_k=${BYRON_GENESIS[1]}
  byron_epoch_length=$(( 10 * byron_k ))
  byron_slot_length=${BYRON_GENESIS[2]}
  echo $(( $byron_genesis_start_time + (($(getCurrentEpoch) * $byron_epoch_length * $byron_slot_length) / 1000) ))
}

# Get epoch end time based on the current one
function getEpochEndTime(){
  # Calculates currentEpoch Start time + 5 days of epoch duration - 10 minutes(600s) to not overlap with next epoch
  echo $(( $(getEpochStartTime)+(5*86400)-(600) ))
}

# Get current timestamp
function getCurrentTime(){
  echo $(printf '%(%s)T\n' -1)
}

# Convert timestamps to UTC time
function timestampToUTC(){
  timestamp=$1
  echo $(date +"%D %T" -ud @$timestamp)
}

# Find the correct time to run the leader slot check command
function getLeaderSlotCheckTime(){
  epochStartTime=$(getEpochStartTime)
  epochEndTime=$(getEpochEndTime)

  # epoch completion percent to check for --next epoch leaderslots
  percentage=75
  checkTimestamp=$(( $epochStartTime+($percentage*($epochEndTime-$epochStartTime)/100) ))

  echo $checkTimestamp
}

# Check leader schedule of next or current epoch depending on $period value
function checkLeadershipSchedule(){
  if [ $period == 'next' ]; then
    targetEpoch=$(( $(getCurrentEpoch)+1 ))
  else
    targetEpoch=$(( $(getCurrentEpoch) ))
  fi
  currentTime=$(getCurrentTime)

  print 'LEADER' "Check is running at: $(timestampToUTC $currentTime) for epoch: $targetEpoch"

  $CCLI query leadership-schedule \
    --socket-path $NETWORK_SOCKET_PATH \
    $network_magic \
    --genesis "$NETWORK_PATH/shelley-genesis.json" \
    --stake-pool-id $(cat $STAKE_POOL_ID) \
    --vrf-signing-key-file "$VRF_KEY" \
    --$period > "$NETWORK_PATH/logs/schedule_$targetEpoch.txt"

  # Removing first two lines and output to a temp file
  echo "$(tail -n +3 $NETWORK_PATH/logs/schedule_$targetEpoch.txt)" > $NETWORK_PATH/logs/leadership_temp.txt

  # Writing in Grafana CSV format
  awk '{print $2,$3","$1","NR}' $NETWORK_PATH/logs/leadership_temp.txt > $NETWORK_PATH/logs/schedule_$targetEpoch.csv
  sed -i '1 i\Time,Slot,No' $NETWORK_PATH/logs/schedule_$targetEpoch.csv

  # Cleanup and show results
  rm $NETWORK_PATH/logs/leadership_temp.txt $NETWORK_PATH/logs/schedule_$targetEpoch.txt
  cat $NETWORK_PATH/logs/schedule_$targetEpoch.csv
  print 'LEADER' "Logs output to $NETWORK_PATH/logs/schedule_$targetEpoch.csv" $green
}

# Run current epoch check
if [ isSynced ];then
  print 'LEADER' "Current epoch: $(getCurrentEpoch)"

  epochStartTimestamp=$(getEpochStartTime)
  print 'LEADER' "Epoch start time: $(timestampToUTC $epochStartTimestamp)"

  epochEndTimestamp=$(getEpochEndTime)
  print 'LEADER' "Epoch end time: $(timestampToUTC $epochEndTimestamp)"

  currentTime=$(getCurrentTime)
  print 'LEADER' "Current cron execution time: $(timestampToUTC $currentTime)"

  if [ $period == 'next' ]; then
    timestampCheckLeaders=$(getLeaderSlotCheckTime)
    timeDifference=$(( $timestampCheckLeaders-$currentTime ))
    print 'LEADER' "Next check time: $(timestampToUTC $timestampCheckLeaders)"
    if [[ $timeDifference -gt 86400 ]]; then
      print 'LEADER' "Too early to run the log check for next epoch" $red; exit 1
    elif [[ $timeDifference -lt 0 ]]; then
      checkLeadershipSchedule
    else
      print 'LEADER' "There were problems on running the script" $red; exit 1
    fi
  elif [ $period == 'current' ]; then
    checkLeadershipSchedule
  fi
else
  print 'LEADER' "Node not fully synced" $red; exit 1
fi
