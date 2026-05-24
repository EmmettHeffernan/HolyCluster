#!/bin/sh

TARGET="$1"

if [ -z "$TARGET" ]; then
  TARGET="latest"
fi

case "$TARGET" in
  latest)
    ssh cortex11 '
      DB="$HOME/holy-cluster/queue/holy_queue.db"
      /usr/local/bin/python3 - <<PY
import sqlite3
from pathlib import Path

db = Path.home() / "holy-cluster/queue/holy_queue.db"
if not db.exists():
    print("No queue database.")
    raise SystemExit(1)

con = sqlite3.connect(db)
row = con.execute("select id, log_path from jobs where log_path is not null order by id desc limit 1").fetchone()
if not row:
    print("No job logs found.")
    raise SystemExit(1)

job_id, log_path = row
print(f"=== JOB {job_id} LOG ===")
print(Path(log_path).read_text(errors="replace"))
PY'
    ;;

  worker)
    ssh cortex11 'tail -n 120 ~/holy-cluster/queue/worker.log 2>/dev/null || echo "No worker log found."'
    ;;

  *)
    ssh cortex11 "/usr/local/bin/python3 ~/holy-cluster/holy_queue.py log '$TARGET'"
    ;;
esac
