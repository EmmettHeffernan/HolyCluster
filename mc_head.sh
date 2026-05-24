#!/bin/sh
set -u

TOTAL="${1:-200000}"
CAL="${2:-20000}"
ARCHIVE_WORKERS="${3:-2}"
CORTEX_WORKERS="${4:-4}"

STAMP="$(date +%Y%m%d_%H%M%S)"
OUT="$HOME/holy-cluster/mc_$STAMP.txt"

rate_of() {
  awk -F= '/^rate=/ {print $2; exit}'
}

echo "HOLY-CLUSTER MULTICORE TEST"
echo "total=$TOTAL cal=$CAL archive_workers=$ARCHIVE_WORKERS cortex_workers=$CORTEX_WORKERS"
echo ""
echo "Calibrating multicore capacity..."

ssh archive09 "python3 ~/holy-cluster/mc_worker.py $CAL ARCHIVE-09 $ARCHIVE_WORKERS" > /tmp/a_mc_cal.txt &
PA=$!

/usr/local/bin/python3 ~/holy-cluster/mc_worker.py "$CAL" CORTEX-11 "$CORTEX_WORKERS" > /tmp/c_mc_cal.txt &
PC=$!

wait "$PA"
wait "$PC"

AR="$(rate_of < /tmp/a_mc_cal.txt)"
CR="$(rate_of < /tmp/c_mc_cal.txt)"

AL="$(awk "BEGIN {printf \"%d\", $TOTAL*($AR/($AR+$CR))}")"
CL=$((TOTAL - AL))

echo "archive_rate=$AR"
echo "cortex_rate=$CR"
echo "archive_loops=$AL"
echo "cortex_loops=$CL"
echo ""

START="$(date +%s)"

ssh archive09 "
cat > ~/holy-cluster/terminal_feed.txt <<EOF
HOLY-CLUSTER MULTICORE JOB
NODE: ARCHIVE-09
STATE: RUNNING
WORKERS: $ARCHIVE_WORKERS
LOOPS: $AL
EOF

python3 ~/holy-cluster/mc_worker.py $AL ARCHIVE-09 $ARCHIVE_WORKERS

cat > ~/holy-cluster/terminal_feed.txt <<EOF
HOLY-CLUSTER MULTICORE JOB
NODE: ARCHIVE-09
STATE: COMPLETE
WORKERS: $ARCHIVE_WORKERS
LOOPS: $AL
EOF
" > /tmp/a_mc_run.txt &

PA=$!

cat > ~/holy-cluster/terminal_feed.txt <<EOF
HOLY-CLUSTER MULTICORE JOB
NODE: CORTEX-11
STATE: RUNNING
WORKERS: $CORTEX_WORKERS
LOOPS: $CL
EOF

/usr/local/bin/python3 ~/holy-cluster/mc_worker.py "$CL" CORTEX-11 "$CORTEX_WORKERS" > /tmp/c_mc_run.txt &
PC=$!

wait "$PA"
wait "$PC"

END="$(date +%s)"
WALL=$((END - START))

cat > ~/holy-cluster/terminal_feed.txt <<EOF
HOLY-CLUSTER MULTICORE JOB
NODE: CORTEX-11
STATE: COMPLETE
WALL: ${WALL}s
EOF

{
echo "HOLY-CLUSTER MULTICORE REPORT"
echo "total=$TOTAL"
echo "calibration=$CAL"
echo "archive_workers=$ARCHIVE_WORKERS"
echo "cortex_workers=$CORTEX_WORKERS"
echo "archive_rate=$AR"
echo "cortex_rate=$CR"
echo "archive_loops=$AL"
echo "cortex_loops=$CL"
echo ""
echo "=== ARCHIVE CAL ==="
cat /tmp/a_mc_cal.txt
echo ""
echo "=== CORTEX CAL ==="
cat /tmp/c_mc_cal.txt
echo ""
echo "=== ARCHIVE RUN ==="
cat /tmp/a_mc_run.txt
echo ""
echo "=== CORTEX RUN ==="
cat /tmp/c_mc_run.txt
echo ""
echo "wall_seconds=$WALL"
echo "split=ARCHIVE-09:$AL,CORTEX-11:$CL"
} > "$OUT"

cat "$OUT"
echo "Saved: $OUT"
