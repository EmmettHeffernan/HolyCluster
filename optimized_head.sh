#!/bin/sh
set -u

TOTAL="${1:-240000}"

ARCHIVE_WORKERS=4
CORTEX_WORKERS=4

ARCHIVE_RATE=2236.06
CORTEX_RATE=6539.38

STAMP="$(date +%Y%m%d_%H%M%S)"
OUT="$HOME/holy-cluster/optimized_$STAMP.txt"

ARCHIVE_LOOPS="$(awk "BEGIN {printf \"%d\", $TOTAL*($ARCHIVE_RATE/($ARCHIVE_RATE+$CORTEX_RATE))}")"
CORTEX_LOOPS=$((TOTAL - ARCHIVE_LOOPS))

echo "HOLY-CLUSTER OPTIMIZED JOB"
echo "total=$TOTAL"
echo "archive_loops=$ARCHIVE_LOOPS workers=$ARCHIVE_WORKERS"
echo "cortex_loops=$CORTEX_LOOPS workers=$CORTEX_WORKERS"
echo ""

START="$(date +%s)"

ssh archive09 "
cat > ~/holy-cluster/terminal_feed.txt <<EOF
HOLY-CLUSTER OPTIMIZED JOB
NODE: ARCHIVE-09
STATE: RUNNING
WORKERS: $ARCHIVE_WORKERS
LOOPS: $ARCHIVE_LOOPS
EOF

python3 ~/holy-cluster/mc_worker.py $ARCHIVE_LOOPS ARCHIVE-09 $ARCHIVE_WORKERS

cat > ~/holy-cluster/terminal_feed.txt <<EOF
HOLY-CLUSTER OPTIMIZED JOB
NODE: ARCHIVE-09
STATE: COMPLETE
WORKERS: $ARCHIVE_WORKERS
LOOPS: $ARCHIVE_LOOPS
EOF
" > /tmp/archive_opt.txt &

PA=$!

cat > ~/holy-cluster/terminal_feed.txt <<EOF
HOLY-CLUSTER OPTIMIZED JOB
NODE: CORTEX-11
STATE: RUNNING
WORKERS: $CORTEX_WORKERS
LOOPS: $CORTEX_LOOPS
EOF

/usr/local/bin/python3 ~/holy-cluster/mc_worker.py "$CORTEX_LOOPS" CORTEX-11 "$CORTEX_WORKERS" > /tmp/cortex_opt.txt &
PC=$!

wait "$PA"
wait "$PC"

END="$(date +%s)"
WALL=$((END - START))

cat > ~/holy-cluster/terminal_feed.txt <<EOF
HOLY-CLUSTER OPTIMIZED JOB
NODE: CORTEX-11
STATE: COMPLETE
WALL: ${WALL}s
EOF

{
echo "HOLY-CLUSTER OPTIMIZED REPORT"
echo "total=$TOTAL"
echo "archive_workers=$ARCHIVE_WORKERS"
echo "cortex_workers=$CORTEX_WORKERS"
echo "archive_rate_profile=$ARCHIVE_RATE"
echo "cortex_rate_profile=$CORTEX_RATE"
echo "archive_loops=$ARCHIVE_LOOPS"
echo "cortex_loops=$CORTEX_LOOPS"
echo ""
echo "=== ARCHIVE RUN ==="
cat /tmp/archive_opt.txt
echo ""
echo "=== CORTEX RUN ==="
cat /tmp/cortex_opt.txt
echo ""
echo "wall_seconds=$WALL"
echo "split=ARCHIVE-09:$ARCHIVE_LOOPS,CORTEX-11:$CORTEX_LOOPS"
} > "$OUT"

cat "$OUT"
echo "Saved: $OUT"
