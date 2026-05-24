#!/bin/sh

BASE="$HOME/holy-cluster"
PY="/usr/local/bin/python3"
QUEUE="$BASE/holy_queue.py"
STOP="$BASE/queue/worker.stop"
PIDFILE="$BASE/queue/worker.pid"
LOG="$BASE/queue/worker.log"

mkdir -p "$BASE/queue"

run_all() {
  echo "HOLY QUEUE RUN-ALL START $(date)"
  while true; do
    OUT="$($PY "$QUEUE" run-next 2>&1)"
    echo "$OUT"
    echo "$OUT" | grep -q "No queued jobs." && break
  done
  echo "HOLY QUEUE RUN-ALL END $(date)"
}

worker_loop() {
  rm -f "$STOP"
  echo $$ > "$PIDFILE"
  echo "HOLY QUEUE WORKER START $(date)" >> "$LOG"

  while true; do
    if [ -f "$STOP" ]; then
      echo "HOLY QUEUE WORKER STOP $(date)" >> "$LOG"
      rm -f "$PIDFILE"
      exit 0
    fi

    OUT="$($PY "$QUEUE" run-next 2>&1)"
    echo "---- $(date) ----" >> "$LOG"
    echo "$OUT" >> "$LOG"

    echo "$OUT" | grep -q "No queued jobs." && sleep 5
  done
}

case "$1" in
  run-all)
    run_all
    ;;
  start)
    if [ -f "$PIDFILE" ]; then
      PID="$(cat "$PIDFILE")"
      if kill -0 "$PID" 2>/dev/null; then
        echo "Worker already running pid=$PID"
        exit 0
      fi
    fi
    nohup "$0" loop >/dev/null 2>&1 &
    echo "Worker started."
    ;;
  loop)
    worker_loop
    ;;
  stop)
    mkdir -p "$BASE/queue"
    touch "$STOP"
    echo "Stop signal written."
    ;;
  status)
    if [ -f "$PIDFILE" ]; then
      PID="$(cat "$PIDFILE")"
      if kill -0 "$PID" 2>/dev/null; then
        echo "Worker running pid=$PID"
        echo "Log: $LOG"
        exit 0
      fi
    fi
    echo "Worker not running."
    ;;
  log)
    tail -n 80 "$LOG" 2>/dev/null || echo "No worker log yet."
    ;;
  *)
    echo "Usage: holy_queue_worker.sh run-all|start|stop|status|log"
    exit 1
    ;;
esac
