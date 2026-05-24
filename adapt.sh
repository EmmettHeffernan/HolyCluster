#!/bin/sh
set -u

TOTAL="${1:-120000}"
CAL="${2:-12000}"
STAMP="$(date +%Y%m%d_%H%M%S)"
OUT="$HOME/holy-cluster/adapt_$STAMP.txt"

rate_of() {
  awk -F= '/^rate=/ {print $2}'
}

echo "Calibrating..."
ssh archive09 "python3 ~/holy-cluster/w.py $CAL ARCHIVE-09" > /tmp/a_cal.txt &
PA=$!
/usr/local/bin/python3 ~/holy-cluster/w.py "$CAL" CORTEX-11 > /tmp/c_cal.txt &
PC=$!
wait "$PA"
wait "$PC"

AR="$(rate_of < /tmp/a_cal.txt)"
CR="$(rate_of < /tmp/c_cal.txt)"

AL="$(awk "BEGIN {printf \"%d\", $TOTAL*($AR/($AR+$CR))}")"
CL=$((TOTAL-AL))

echo "ARCHIVE_RATE=$AR"
echo "CORTEX_RATE=$CR"
echo "ARCHIVE_LOOPS=$AL"
echo "CORTEX_LOOPS=$CL"
echo ""

START="$(date +%s)"

ssh archive09 "
cat > ~/holy-cluster/terminal_feed.txt <<EOF
HOLY-CLUSTER ADAPTIVE JOB
NODE: ARCHIVE-09
STATE: RUNNING
LOOPS: $AL
EOF
python3 ~/holy-cluster/w.py $AL ARCHIVE-09
cat > ~/holy-cluster/terminal_feed.txt <<EOF
HOLY-CLUSTER ADAPTIVE JOB
NODE: ARCHIVE-09
STATE: COMPLETE
LOOPS: $AL
EOF
" > /tmp/a_run.txt &

PA=$!

cat > ~/holy-cluster/terminal_feed.txt <<EOF
HOLY-CLUSTER ADAPTIVE JOB
NODE: CORTEX-11
STATE: RUNNING
LOOPS: $CL
EOF

/usr/local/bin/python3 ~/holy-cluster/w.py "$CL" CORTEX-11 > /tmp/c_run.txt &
PC=$!

wait "$PA"
wait "$PC"

END="$(date +%s)"
WALL=$((END-START))

cat > ~/holy-cluster/terminal_feed.txt <<EOF
HOLY-CLUSTER ADAPTIVE JOB
NODE: CORTEX-11
STATE: COMPLETE
WALL: ${WALL}s
EOF

{
echo "HOLY-CLUSTER ADAPTIVE REPORT"
echo "total=$TOTAL"
echo "calibration=$CAL"
echo "archive_rate=$AR"
echo "cortex_rate=$CR"
echo "archive_loops=$AL"
echo "cortex_loops=$CL"
echo ""
echo "=== ARCHIVE CAL ==="
cat /tmp/a_cal.txt
echo ""
echo "=== CORTEX CAL ==="
cat /tmp/c_cal.txt
echo ""
echo "=== ARCHIVE RUN ==="
cat /tmp/a_run.txt
echo ""
echo "=== CORTEX RUN ==="
cat /tmp/c_run.txt
echo ""
echo "wall_seconds=$WALL"
echo "split=ARCHIVE-09:$AL,CORTEX-11:$CL"
} > "$OUT"

cat "$OUT"
echo "Saved: $OUT"
