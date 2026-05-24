#!/usr/bin/env python3
import sqlite3, sys, subprocess, time, os
from pathlib import Path

BASE = Path.home() / "holy-cluster"
QDIR = BASE / "queue"
DB = QDIR / "holy_queue.db"
LOGS = QDIR / "logs"

def db():
    QDIR.mkdir(parents=True, exist_ok=True)
    LOGS.mkdir(parents=True, exist_ok=True)
    con = sqlite3.connect(DB)
    con.execute("""
    create table if not exists jobs(
      id integer primary key autoincrement,
      status text not null,
      command text not null,
      created_at text not null,
      started_at text,
      finished_at text,
      exit_code integer,
      log_path text
    )
    """)
    con.commit()
    return con

def now():
    return time.strftime("%Y-%m-%d %H:%M:%S")

def init():
    con = db()
    print(f"HOLY_QUEUE_READY db={DB}")

def submit(args):
    if not args:
        print("Usage: holy_queue.py submit <command>")
        return 2
    cmd = " ".join(args)
    con = db()
    cur = con.execute(
        "insert into jobs(status,command,created_at) values(?,?,?)",
        ("queued", cmd, now())
    )
    con.commit()
    print(f"JOB_SUBMITTED id={cur.lastrowid}")
    print(f"command={cmd}")

def list_jobs():
    con = db()
    rows = con.execute("""
      select id,status,created_at,coalesce(exit_code,''),command
      from jobs order by id desc limit 20
    """).fetchall()
    if not rows:
        print("No jobs.")
        return
    print("ID | STATUS | CREATED | EXIT | COMMAND")
    print("-" * 80)
    for r in rows:
        print(f"{r[0]} | {r[1]} | {r[2]} | {r[3]} | {r[4][:80]}")

def get_job(job_id):
    con = db()
    row = con.execute("select * from jobs where id=?", (job_id,)).fetchone()
    return con, row

def show(job_id):
    con, row = get_job(job_id)
    if not row:
        print("Job not found.")
        return 1
    cols = [d[0] for d in con.execute("select * from jobs limit 1").description]
    for k, v in zip(cols, row):
        print(f"{k}={v}")

def log(job_id):
    con, row = get_job(job_id)
    if not row:
        print("Job not found.")
        return 1
    log_path = row[7]
    if not log_path or not Path(log_path).exists():
        print("No log found.")
        return 1
    print(Path(log_path).read_text(errors="replace"))

def run_next():
    con = db()
    row = con.execute(
        "select id,command from jobs where status='queued' order by id asc limit 1"
    ).fetchone()
    if not row:
        print("No queued jobs.")
        return 0

    job_id, cmd = row
    log_path = LOGS / f"job_{job_id}.log"

    con.execute(
        "update jobs set status=?,started_at=?,log_path=? where id=?",
        ("running", now(), str(log_path), job_id)
    )
    con.commit()

    print(f"RUNNING_JOB id={job_id}")
    print(f"command={cmd}")
    print(f"log={log_path}")

    with open(log_path, "w") as f:
        f.write(f"HOLY QUEUE JOB {job_id}\n")
        f.write(f"START={now()}\n")
        f.write(f"COMMAND={cmd}\n")
        f.write("=" * 60 + "\n")
        f.flush()

        proc = subprocess.run(
            cmd,
            shell=True,
            cwd=str(BASE),
            stdout=f,
            stderr=subprocess.STDOUT
        )

        f.write("=" * 60 + "\n")
        f.write(f"END={now()}\n")
        f.write(f"EXIT_CODE={proc.returncode}\n")

    status = "done" if proc.returncode == 0 else "failed"
    con.execute(
        "update jobs set status=?,finished_at=?,exit_code=? where id=?",
        (status, now(), proc.returncode, job_id)
    )
    con.commit()

    print(f"JOB_FINISHED id={job_id} status={status} exit={proc.returncode}")
    return proc.returncode

def main():
    if len(sys.argv) < 2:
        print("Usage: holy_queue.py init|submit|list|run-next|show|log")
        return 2

    cmd = sys.argv[1]

    if cmd == "init":
        return init() or 0
    if cmd == "submit":
        return submit(sys.argv[2:]) or 0
    if cmd == "list":
        return list_jobs() or 0
    if cmd == "run-next":
        return run_next() or 0
    if cmd == "show":
        return show(int(sys.argv[2]))
    if cmd == "log":
        return log(int(sys.argv[2]))

    print(f"Unknown queue command: {cmd}")
    return 2

if __name__ == "__main__":
    raise SystemExit(main())
