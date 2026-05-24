#!/usr/bin/env python3
import sqlite3, subprocess, time
from pathlib import Path

BASE = Path.home() / "holy-cluster"
QUEUE_DB = BASE / "queue" / "holy_queue.db"
ART_DB = BASE / "artifacts" / "artifacts.db"
KB_DB = BASE / "kb" / "holy_kb.db"
OUTDIR = BASE / "briefs"

def rows(db, q, args=()):
    if not db.exists():
        return []
    con = sqlite3.connect(db)
    try:
        return con.execute(q, args).fetchall()
    finally:
        con.close()

def line(s=""):
    print(s)

def main():
    OUTDIR.mkdir(parents=True, exist_ok=True)
    stamp = time.strftime("%Y%m%d_%H%M%S")
    path = OUTDIR / f"holy_brief_{stamp}.md"

    q_stats = rows(QUEUE_DB, "select status,count(*) from jobs group by status")
    recent_jobs = rows(QUEUE_DB, """
        select id,status,coalesce(exit_code,''),command
        from jobs order by id desc limit 8
    """)

    recent_artifacts = rows(ART_DB, """
        select id,type,created_at,path,coalesce(note,'')
        from artifacts order by id desc limit 8
    """)

    open_tasks = rows(KB_DB, """
        select items.id, projects.name, items.title, items.created_at
        from items join projects on projects.id=items.project_id
        where items.type='task' and items.status='open'
        order by items.id desc limit 12
    """)

    decisions = rows(KB_DB, """
        select items.id, projects.name, items.title, items.created_at
        from items join projects on projects.id=items.project_id
        where items.type='decision'
        order by items.id desc limit 8
    """)

    projects = rows(KB_DB, """
        select name,status,coalesce(description,'')
        from projects order by updated_at desc limit 10
    """)

    parts = []
    parts.append("# HOLYOPS BRIEF")
    parts.append("")
    parts.append(f"Generated: {time.strftime('%Y-%m-%d %H:%M:%S')}")
    parts.append("")

    parts.append("## Queue Status")
    if q_stats:
        for status, count in q_stats:
            parts.append(f"- {status}: {count}")
    else:
        parts.append("- no queue database or no jobs")
    parts.append("")

    parts.append("## Recent Jobs")
    if recent_jobs:
        for jid, status, exit_code, cmd in recent_jobs:
            parts.append(f"- [{jid}] {status} exit={exit_code} :: `{cmd}`")
    else:
        parts.append("- none")
    parts.append("")

    parts.append("## Open Tasks")
    if open_tasks:
        for tid, project, title, created in open_tasks:
            parts.append(f"- [{tid}] **{project}** :: {title} ({created})")
    else:
        parts.append("- none")
    parts.append("")

    parts.append("## Recent Decisions")
    if decisions:
        for did, project, title, created in decisions:
            parts.append(f"- [{did}] **{project}** :: {title} ({created})")
    else:
        parts.append("- none")
    parts.append("")

    parts.append("## Recent Artifacts")
    if recent_artifacts:
        for aid, typ, created, apath, note in recent_artifacts:
            parts.append(f"- [{aid}] {typ} :: {apath}")
            if note:
                parts.append(f"  - {note}")
    else:
        parts.append("- none")
    parts.append("")

    parts.append("## Active Projects")
    if projects:
        for name, status, desc in projects:
            parts.append(f"- **{name}** [{status}] — {desc}")
    else:
        parts.append("- none")
    parts.append("")

    path.write_text("\n".join(parts))

    artifact = BASE / "holy_artifact.py"
    if artifact.exists():
        subprocess.run(
            ["/usr/local/bin/python3", str(artifact), "add", "brief", str(path), "HolyOps operating brief"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )

    print(path.read_text())
    print("")
    print(f"BRIEF_PATH={path}")

if __name__ == "__main__":
    main()
