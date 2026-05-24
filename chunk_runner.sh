#!/bin/sh

NODE="$1"
PY="$2"
TOTAL="$3"
CHUNKS="$4"

i=1
BASE=$((TOTAL / CHUNKS))

while [ "$i" -le "$CHUNKS" ]; do
  if [ "$i" -eq "$CHUNKS" ]; then
    DONE=$((BASE * (CHUNKS - 1)))
    LOOPS=$((TOTAL - DONE))
  else
    LOOPS="$BASE"
  fi

  echo "running $NODE chunk $i/$CHUNKS loops=$LOOPS"
  "$PY" "$HOME/holy-cluster/chunk_worker.py" "$LOOPS" "$NODE" "$i"

  i=$((i + 1))
done
