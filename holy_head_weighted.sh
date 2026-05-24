#!/bin/sh

set -u

TOTAL_LOOPS="${1:-100000}"
ARCHIVE_LOOPS=$((TOTAL_LOOPS * 40 / 100))
CORTEX_LOOPS=$((TOTAL_LOOPS - ARCHIVE_LOOPS))

STAMP="$(date '+%Y%m%d_%H%M%S')"
OUT="$HOME/holy-cluster/head_weighted_$STAMP.txt"

echo "HOLY-CLUSTER HEAD-NODE WEIGHTED JOB" > "$OUT"
echo "created_by=CORTEX-11" >> "$OUT"
echo "triggered_by=UPLINK-iSH" >> "$OUT"
echo "time=$(date '+%Y-%m-%d %H:%M:%S')" >> "$OUT"
echo "total_loops=$TOTAL_LOOPS" >> "$OUT"
echo "archive09_loops=$ARCHIVE_LOOPS" >> "$OUT"
echo "cortex11_loops=$CORTEX_LOOPS" >> "$OUT"
echo "" >> "$OUT"

echo "CORTEX-11 is acting as head node."
echo "TOTAL_LOOPS=$TOTAL_LOOPS"
echo "ARCHIVE_LOOPS=$ARCHIVE_LOOPS"
echo "CORTEX_LOOPS=$CORTEX_LOOPS"
echo ""

START="$(date +%s)"

ssh archive09 "
cat > ~/holy-cluster/terminal_feed.txt <<EOF
HOLY-CLUSTER HEAD JOB
NODE: ARCHIVE-09
HEAD: CORTEX-11
STATE: RUNNING
LOOPS: $ARCHIVE_LOOPS
EOF

python3 ~/holy-cluster/weighted_worker.py $ARCHIVE_LOOPS ARCHIVE-09

cat > ~/holy-cluster/terminal_feed.txt <<EOF
HOLY-CLUSTER HEAD JOB
NODE: ARCHIVE-09
HEAD: CORTEX-11
STATE: COMPLETE
LOOPS: $ARCHIVE_LOOPS
EOF
" > /tmp/archive09_head_weighted.txt &

PID_A=$!

cat > ~/holy-cluster/terminal_feed.txt <<EOF
HOLY-CLUSTER HEAD JOB
NODE: CORTEX-11
HEAD: CORTEX-11
STATE: RUNNING
LOOPS: $CORTEX_LOOPS
EOF

/usr/local/bin/python3 ~/holy-cluster/weighted_worker.py $CORTEX_LOOPS CORTEX-11 > /tmp/cortex11_head_weighted.txt &
PID_C=$!

wait "$PID_A"
wait "$PID_C"

END="$(date +%s)"
WALL_SECONDS=$((END - START))

cat > ~/holy-cluster/terminal_feed.txt <<EOF
HOLY-CLUSTER HEAD JOB
NODE: CORTEX-11
HEAD: CORTEX-11
STATE: COMPLETE
WALL_SECONDS: $WALL_SECONDS
EOF

{
  echo "======================================"
  echo "ARCHIVE-09 RESULT"
  echo "--------------------------------------"
  cat /tmp/archive09_head_weighted.txt
  echo ""
  echo "======================================"
  echo "CORTEX-11 RESULT"
  echo "--------------------------------------"
  cat /tmp/cortex11_head_weighted.txt
  echo ""
  echo "======================================"
  echo "SUMMARY"
  echo "--------------------------------------"
  echo "head_weighted_wall_seconds=$WALL_SECONDS"
  echo "split=ARCHIVE-09:${ARCHIVE_LOOPS},CORTEX-11:${CORTEX_LOOPS}"
} >> "$OUT"

cat "$OUT"
echo ""
echo "Saved report: $OUT"
