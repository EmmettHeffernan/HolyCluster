#!/usr/bin/env python3
import os
import sqlite3
import subprocess
import sys
import time
from pathlib import Path

BASE = Path.home() / "holy-cluster"
ADB_DIR = BASE / "artifacts"
DB = ADB_DIR / "artifacts.db"

def now():
    return time.strftime("%Y-%m-%d %H:%M:%S")

def con():
    ADB_DIR.mkdir(parents=True, exist_ok=True)
    c = sqlite3.connect(DB)
    c.execute("""
    create table if not exists artifacts(
      id integer primary key autoincrement,
      type text not null,
      path text not null,
      note text,
      created_at text not null
    )
    """)
    c.commit()
    return c

def init():
    con()
    print(f"HOLY_ARTIFACTS_READY db={DB}")

def add(args):
    if len(args) < 2:
        print("Usage: holy_artifact.py add <type> <path> [note]")
        return 2
    typ = args[0]
    path = os.path.expanduser(args[1])
    note = " ".join(args[2:]) if len(args) > 2 else ""
    c = con()
    cur = c.execute(
        "insert into artifacts(type,path,note,created_at) values(?,?,?,?)",
        (typ, path, note, now())
    )
    c.commit()
    print(f"ARTIFACT_ADDED id={cur.lastrowid}")
    print(f"type={typ}")
    print(f"path={path}")
    if note:
        print(f"note={note}")

def list_artifacts():
    c = con()
    rows = c.execute("""
      select id,type,created_at,path,note
      from artifacts
      order by id desc
      limit 25
    """).fetchall()

    if not rows:
        print("No artifacts.")
        return

    print("ID | TYPE | CREATED | PATH | NOTE")
    print("-" * 100)
    for i, typ, created, path, note in rows:
        print(f"{i} | {typ} | {created} | {path} | {note or ''}")

def latest():
    c = con()
    row = c.execute("""
      select id,type,created_at,path,note
      from artifacts
      order by id desc
      limit 1
    """).fetchone()

    if not row:
        print("No artifacts.")
        return 1

    i, typ, created, path, note = row
    print(f"id={i}")
    print(f"type={typ}")
    print(f"created_at={created}")
    print(f"path={path}")
    print(f"note={note or ''}")

def show(job_id):
    c = con()
    row = c.execute("""
      select id,type,created_at,path,note
      from artifacts
      where id=?
    """, (job_id,)).fetchone()

    if not row:
        print("Artifact not found.")
        return 1

    i, typ, created, path, note = row
    print(f"id={i}")
    print(f"type={typ}")
    print(f"created_at={created}")
    print(f"path={path}")
    print(f"note={note or ''}")

def open_latest():
    c = con()
    row = c.execute("select path from artifacts order by id desc limit 1").fetchone()
    if not row:
        print("No artifacts.")
        return 1

    path = os.path.expanduser(row[0])
    print(path)

    if Path(path).exists():
        subprocess.run(["open", path])
    else:
        print("Path does not exist on CORTEX-11.")
        return 1

def main():
    if len(sys.argv) < 2:
        print("Usage: holy_artifact.py init|add|list|latest|show|open")
        return 2

    cmd = sys.argv[1]

    if cmd == "init":
        return init() or 0
    if cmd == "add":
        return add(sys.argv[2:]) or 0
    if cmd == "list":
        return list_artifacts() or 0
    if cmd == "latest":
        return latest() or 0
    if cmd == "show":
        return show(int(sys.argv[2]))
    if cmd == "open":
        return open_latest() or 0

    print(f"Unknown artifact command: {cmd}")
    return 2

if __name__ == "__main__":
    raise SystemExit(main())
