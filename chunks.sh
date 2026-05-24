#!/bin/sh
set -u

TOTAL="${1:-160000}"
CAL="${2:-10000}"
CHUNKS="${3:-8}"

STAMP="$(date +%Y%m%d_%H%M%S)"
OUT="$HOME/holy-cluster/chunks_$STAMP.txt"

rate_of() {
  awk -F= '/^rate=/ {print $2; exit}'
}

run_chunks() {
  NODE="$1"
  PY="$2"
  TOTAL_LOOPS="$3"
  CHUNK_COUNT="$4"
  OUTFILE="$5"

  i=1
  while [ "$i" -le "$CHUNK_COUNT" ]; do
    LOOPS=$((TOTAL_LOOPS / CHUNK_COUNT))
    if [ "$i" -eq "$CHUNK_COUNT" ]; then
      DONE=$((LOOPS * (CHUNK_COUNT - 1)))
      LOOPS=$((TOTAL_LOOPS - DONE))
    fi

    echo "running $NODE chunk $i/$CHUNK_COUNT loops=$LOOPS" >> "$OUTFILE"
    $PY ~/holy-cluster/chunk_worker.py "$LOOPS" "$NODE" "$i" >> "$OUTFILE"
    i=$((i+1))
  done
}

echo "HOLY-CLUSTER MULTI-CHUNK SCHEDULER"
echo "total=$TOTAL calibration=$CAL chunks=$CHUNKS"
echo ""

echo "Calibrating nodes..."

ssh archive09 "python3 ~/holy-cluster/chunk_worker.py $CAL ARCHIVE-09 CAL" > /tmp/a_cal.txt &
PA=$!

/usr/local/bin/python3 ~/holy-cluster/chunk_worker.py "$CAL" CORTEX-11 CAL > /tmp/c_cal.txt &
PC=$!

wait "$PA"
wait "$PC"

AR="$(rate_of < /tmp/a_cal.txt)"
CR="$(rate_of < /tmp/c_cal.txt)"

AL="$(awk "BEGIN {printf \"%d\", $TOTAL*($AR/($AR+$CR))}")"
CL=$((TOTAL-AL))

AC="$(awk "BEGIN {printf \"%d\", $CHUNKS*($AR/($AR+$CR))}")"
[ "$AC" -lt 1 ] && AC=1
[ "$AC" -ge "$CHUNKS" ] && AC=$((CHUNKS-1))
CC=$((CHUNKS-AC))

echo "archive_rate=$AR"
echo "cortex_rate=$CR"
echo "archive_loops=$AL"
echo "cortex_loops=$CL"
echo "archive_chunks=$AC"
echo "cortex_chunks=$CC"
echo ""

cat > "$OUT" <<EOF
HOLY-CLUSTER MULTI-CHUNK REPORT
created_by=CORTEX-11
triggered_by=UPLINK-iSH
time=$(date '+%Y-%m-%d %H:%M:%S')
total_loops=$TOTAL
calibration_loops=$CAL
total_chunks=$CHUNKS
archive_rate=$AR
cortex_rate=$CR
archive_loops=$AL
cortex_loops=$CL
archive_chunks=$AC
cortex_chunks=$CC

=== ARCHIVE CAL ===
$(cat /tmp/a_cal.txt)

=== CORTEX CAL ===
$(cat /tmp/c_cal.txt)

EOF

START="$(date +%s)"

ssh archive09 "cat > ~/holy-cluster/terminal_feed.txt <<EOF
HOLY-CLUSTER MULTI-CHUNK JOB
NODE: ARCHIVE-09
STATE: RUNNING
CHUNKS: $AC
LOOPS: $AL
EOF
cd ~/holy-cluster
run_one() {
  NODE=\"ARCHIVE-09\"
  i=1
  while [ \"\$i\" -le \"$AC\" ]; do
    LOOPS=$((AL / AC))
    if [ \"\$i\" -eq \"$AC\" ]; then
      DONE=$(( (AL / AC) * (AC - 1) ))
      LOOPS=$((AL - DONE))
    fi
    python3 ~/holy-cluster/chunk_worker.py \"\$LOOPS\" \"\$NODE\" \"\$i\"
    i=\$((i+1))
  done
}
run_one
cat > ~/holy-cluster/terminal_feed.txt <<EOF
HOLY-CLUSTER MULTI-CHUNK JOB
NODE: ARCHIVE-09
STATE: COMPLETE
CHUNKS: $AC
LOOPS: $AL
EOF
" > /tmp/a_chunks.txt &

PA=$!

cat > ~/holy-cluster/terminal_feed.txt <<EOF
HOLY-CLUSTER MULTI-CHUNK JOB
NODE: CORTEX-11
STATE: RUNNING
CHUNKS: $CC
LOOPS: $CL
EOF

run_chunks CORTEX-11 /usr/local/bin/python3 "$CL" "$CC" /tmp/c_chunks.txt &
PC=$!

wait "$PA"
wait "$PC"

END="$(date +%s)"
WALL=$((END-START))

cat > ~/holy-cluster/terminal_feed.txt <<EOF
HOLY-CLUSTER MULTI-CHUNK JOB
NODE: CORTEX-11
STATE: COMPLETE
WALL: ${WALL}s
EOF

{
echo "=== ARCHIVE CHUNKS ==="
cat /tmp/a_chunks.txt
echo ""
echo "=== CORTEX CHUNKS ==="
cat /tmp/c_chunks.txt
echo ""
echo "=== SUMMARY ==="
echo "wall_seconds=$WALL"
echo "split=ARCHIVE-09:${AL}loops/${AC}chunks,CORTEX-11:${CL}loops/${CC}chunks"
} >> "$OUT"

cat "$OUT"
echo "Saved: $OUT"
