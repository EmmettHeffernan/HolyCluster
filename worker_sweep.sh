#!/bin/sh
set -u

LOOPS="${1:-40000}"
OUT="$HOME/holy-cluster/worker_sweep_$(date +%Y%m%d_%H%M%S).txt"

echo "HOLY-CLUSTER WORKER SWEEP" > "$OUT"
echo "loops_per_test=$LOOPS" >> "$OUT"
echo "" >> "$OUT"

echo "Testing ARCHIVE-09..."
echo "=== ARCHIVE-09 ===" >> "$OUT"

for W in 1 2 3 4; do
  echo "ARCHIVE workers=$W"
  ssh archive09 "python3 ~/holy-cluster/mc_worker.py $LOOPS ARCHIVE-09 $W" >> "$OUT"
  echo "" >> "$OUT"
done

echo "Testing CORTEX-11..."
echo "=== CORTEX-11 ===" >> "$OUT"

for W in 1 2 4 6 8; do
  echo "CORTEX workers=$W"
  /usr/local/bin/python3 ~/holy-cluster/mc_worker.py "$LOOPS" CORTEX-11 "$W" >> "$OUT"
  echo "" >> "$OUT"
done

cat "$OUT"
echo "Saved: $OUT"
