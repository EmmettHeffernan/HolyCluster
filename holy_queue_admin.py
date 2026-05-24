#!/usr/bin/env python3
import sqlite3, sys
from pathlib import Path

BASE = Path.home() / "holy-cluster"
DB = BASE / "queue" / "holy_queue.db"

def con():
    if not DB.exists():
        print("Queue DB not found. Run: holy q init")
        raise SystemExit(1)
    return sqlite3.connect(DB)

def stats():
    c = con()
    rows = c.execute("select status,count(*) from jobs group by status").fetchall()
    if not rows:
        print("No jobs.")
        return
    for status, count in rows:
        print(f"{status}={count}")

def cancel(job_id):
    c = con()
    c.execute("update jobs set status='cancelled' where id=? and status='queued'", (job_id,))
    c.commit()
    print(f"cancelled_if_queued={job_id}")

def retry(job_id):
    c = con()
    row = c.execute("select command from jobs where id=?", (job_id,)).fetchone()
    if not row:
        print("Job not found.")
        return 1
    cmd = row[0]
    c.execute(
        "insert into jobs(status,command,created_at) values('queued',?,datetime('now'))",
        (cmd,)
    )
    c.commit()
    print(f"retried_job={job_id}")
    print(f"new_job_id={c.execute('select last_insert_rowid()').fetchone()[0]}")

def clean():
    c = con()
    c.execute("delete from jobs where status in ('done','cancelled')")
    c.commit()
    print("cleaned_done_and_cancelled_jobs")

def main():
    if len(sys.argv) < 2:
        print("Usage: holy_queue_admin.py stats|cancel <id>|retry <id>|clean")
        return 2
    cmd = sys.argv[1]
    if cmd == "stats":
        stats()
    elif cmd == "cancel":
        cancel(int(sys.argv[2]))
    elif cmd == "retry":
        retry(int(sys.argv[2]))
    elif cmd == "clean":
        clean()
    else:
        print("Unknown command.")
        return 2

if __name__ == "__main__":
    raise SystemExit(main())
