#!/bin/sh

MISSION="$*"

if [ -z "$MISSION" ]; then
  MISSION="First contact: record that holy-cluster is operational."
fi

STAMP=$(date "+%Y-%m-%d %H:%M:%S")

echo "======================================"
echo "          HOLY-CLUSTER MISSION"
echo "======================================"
echo "MISSION=$MISSION"
echo "DISPATCH_TIME=$STAMP"
echo ""

echo "[CORTEX-11]"
echo "Cortex accepted mission."
echo "Generating command packet..."
echo ""

echo "[ARCHIVE-09]"
ssh archive09 "mkdir -p ~/holy-cluster/logs && cat >> ~/holy-cluster/logs/mission_log.txt <<EOF
[$STAMP] MISSION RECEIVED
FROM=CORTEX-11
TO=ARCHIVE-09
MISSION=$MISSION
STATUS=RECORDED

EOF
tail -n 8 ~/holy-cluster/logs/mission_log.txt"

echo ""
echo "MISSION STATUS: COMPLETE"
echo "======================================"
