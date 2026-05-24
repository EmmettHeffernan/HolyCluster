#!/usr/bin/env python3
import json, re, sqlite3, subprocess, sys, time
from pathlib import Path
from html import escape

BASE = Path.home() / "holy-cluster"
KBDIR = BASE / "kb"
DB = KBDIR / "holy_kb.db"
ARTDB = BASE / "artifacts" / "artifacts.db"

def now():
    return time.strftime("%Y-%m-%d %H:%M:%S")

def slugify(s):
    s = re.sub(r"[^a-zA-Z0-9]+", "-", s.lower()).strip("-")
    return s or "project"

def con():
    KBDIR.mkdir(parents=True, exist_ok=True)
    c = sqlite3.connect(DB)
    c.execute("""
    create table if not exists projects(
      id integer primary key autoincrement,
      name text unique not null,
      slug text not null,
      status text not null default 'active',
      description text,
      created_at text not null,
      updated_at text not null
    )
    """)
    c.execute("""
    create table if not exists items(
      id integer primary key autoincrement,
      type text not null,
      project_id integer,
      title text,
      body text,
      url text,
      status text not null,
      created_at text not null,
      updated_at text not null,
      foreign key(project_id) references projects(id)
    )
    """)
    c.execute("""
    create table if not exists artifact_links(
      id integer primary key autoincrement,
      project_id integer not null,
      artifact_id integer not null,
      note text,
      created_at text not null,
      foreign key(project_id) references projects(id)
    )
    """)
    c.commit()
    return c

def get_project_id(c, name, create=True):
    row = c.execute("select id from projects where name=?", (name,)).fetchone()
    if row:
        return row[0]
    if not create:
        return None
    t = now()
    c.execute(
        "insert into projects(name,slug,description,created_at,updated_at) values(?,?,?,?,?)",
        (name, slugify(name), "", t, t),
    )
    c.commit()
    return c.execute("select id from projects where name=?", (name,)).fetchone()[0]

def init(args):
    c = con()
    for name, desc in [
        ("Inbox", "Unsorted capture"),
        ("HolyOps", "Automation appliance and cluster operating system"),
        ("Business", "Opportunities, positioning, and monetization"),
        ("Voynich Workbench", "Voynich Manuscript research and hypothesis testing"),
        ("AudioVisionAI", "Audio, video, and signal-processing experiments"),
        ("Game Lab", "Game development, procedural systems, and simulations"),
    ]:
        pid = get_project_id(c, name, True)
        c.execute("update projects set description=?, updated_at=? where id=?", (desc, now(), pid))
    c.commit()
    print(f"HOLY_KB_READY db={DB}")

def project_add(args):
    if not args:
        print("Usage: project-add <name> [description]")
        return 2
    name = args[0]
    desc = " ".join(args[1:]) if len(args) > 1 else ""
    c = con()
    pid = get_project_id(c, name, True)
    if desc:
        c.execute("update projects set description=?, updated_at=? where id=?", (desc, now(), pid))
        c.commit()
    print(f"PROJECT id={pid} name={name}")

def projects(args):
    c = con()
    rows = c.execute("select id,name,status,coalesce(description,'') from projects order by name").fetchall()
    print("ID | STATUS | NAME | DESCRIPTION")
    print("-" * 80)
    for r in rows:
        print(f"{r[0]} | {r[2]} | {r[1]} | {r[3]}")

def add_item(args, typ):
    if len(args) < 2:
        print(f"Usage: {typ} <project> <text>")
        return 2
    project = args[0]
    body = " ".join(args[1:])
    title = body[:80]
    status = "open" if typ == "task" else "stored"
    c = con()
    pid = get_project_id(c, project, True)
    t = now()
    cur = c.execute(
        "insert into items(type,project_id,title,body,url,status,created_at,updated_at) values(?,?,?,?,?,?,?,?)",
        (typ, pid, title, body, "", status, t, t),
    )
    c.commit()
    print(f"{typ.upper()}_ADDED id={cur.lastrowid} project={project}")

def source(args):
    if len(args) < 3:
        print("Usage: source <project> <title> <url-or-path> [note]")
        return 2
    project, title, url = args[0], args[1], args[2]
    body = " ".join(args[3:]) if len(args) > 3 else ""
    c = con()
    pid = get_project_id(c, project, True)
    t = now()
    cur = c.execute(
        "insert into items(type,project_id,title,body,url,status,created_at,updated_at) values(?,?,?,?,?,?,?,?)",
        ("source", pid, title, body, url, "stored", t, t),
    )
    c.commit()
    print(f"SOURCE_ADDED id={cur.lastrowid} project={project}")

def done(args):
    if not args:
        print("Usage: done <task_id>")
        return 2
    c = con()
    c.execute("update items set status='done', updated_at=? where id=? and type='task'", (now(), int(args[0])))
    c.commit()
    print(f"TASK_DONE id={args[0]}")

def link_artifact(args):
    if len(args) < 2:
        print("Usage: link-artifact <project> <artifact_id> [note]")
        return 2
    project = args[0]
    artifact_id = int(args[1])
    note = " ".join(args[2:]) if len(args) > 2 else ""
    c = con()
    pid = get_project_id(c, project, True)
    cur = c.execute(
        "insert into artifact_links(project_id,artifact_id,note,created_at) values(?,?,?,?)",
        (pid, artifact_id, note, now()),
    )
    c.commit()
    print(f"ARTIFACT_LINKED link_id={cur.lastrowid} project={project} artifact_id={artifact_id}")

def artifact_summary(artifact_id):
    if not ARTDB.exists():
        return None
    c = sqlite3.connect(ARTDB)
    row = c.execute(
        "select id,type,created_at,path,coalesce(note,'') from artifacts where id=?",
        (artifact_id,)
    ).fetchone()
    c.close()
    return row

def project_view(args):
    if not args:
        print("Usage: project <name>")
        return 2

    name = " ".join(args)
    c = con()
    row = c.execute(
        "select id,name,status,coalesce(description,'') from projects where name=?",
        (name,)
    ).fetchone()

    if not row:
        print(f"Project not found: {name}")
        return 1

    pid, pname, status, desc = row
    print(f"PROJECT={pname}")
    print(f"STATUS={status}")
    print(f"DESCRIPTION={desc}")
    print("")
    for typ in ["task", "decision", "note", "source"]:
        rows = c.execute("""
          select id,title,url,status,created_at
          from items
          where project_id=? and type=?
          order by id desc limit 12
        """, (pid, typ)).fetchall()

        print(f"=== {typ.upper()}S ===")
        if not rows:
            print("none")

        for item_id, title, url, item_status, created in rows:
            extra = f" url={url}" if url else ""
            print(f"[{item_id}] {item_status} {created} :: {title}{extra}")
        print("")

    links = c.execute("""
      select artifact_id,note,created_at
      from artifact_links
      where project_id=?
      order by id desc limit 12
    """, (pid,)).fetchall()

    print("=== ARTIFACTS ===")
    if not links:
        print("none")

    for artifact_id, note, created in links:
        a = artifact_summary(artifact_id)
        if a:
            print(f"[artifact {a[0]}] {a[1]} {a[2]} :: {a[3]} :: {note or a[4]}")
        else:
            print(f"[artifact {artifact_id}] {created} :: {note}")

def search(args):
    if not args:
        print("Usage: search <query>")
        return 2

    q = "%" + " ".join(args) + "%"
    c = con()

    rows = c.execute("""
      select items.id, items.type, projects.name, items.title, items.status, items.created_at
      from items
      left join projects on projects.id=items.project_id
      where items.title like ? or items.body like ? or items.url like ? or projects.name like ?
      order by items.id desc limit 30
    """, (q, q, q, q)).fetchall()

    if not rows:
        print("No matches.")
        return

    for item_id, typ, project, title, status, created in rows:
        print(f"[{item_id}] {typ} project={project} status={status} created={created} :: {title}")

def next_tasks(args):
    c = con()

    rows = c.execute("""
      select items.id, projects.name, items.title, items.created_at
      from items
      join projects on projects.id=items.project_id
      where items.type='task' and items.status='open'
      order by items.id desc limit 25
    """).fetchall()

    if not rows:
        print("No open tasks.")
        return

    print("OPEN TASKS")
    print("-" * 80)
    for item_id, project, title, created in rows:
        print(f"[{item_id}] {project} :: {title} ({created})")

def report(args):
    if not args:
        print("Usage: report <project>")
        return 2

    name = " ".join(args)
    c = con()

    row = c.execute(
        "select id,name,coalesce(description,'') from projects where name=?",
        (name,)
    ).fetchone()

    if not row:
        print(f"Project not found: {name}")
        return 1

    pid, pname, desc = row
    outdir = KBDIR / "reports"
    outdir.mkdir(parents=True, exist_ok=True)
    path = outdir / f"kb_{slugify(pname)}_{time.strftime('%Y%m%d_%H%M%S')}.md"

    items = c.execute("""
      select type,id,title,body,url,status,created_at
      from items
      where project_id=?
      order by type,id desc
    """, (pid,)).fetchall()

    links = c.execute("""
      select artifact_id,note,created_at
      from artifact_links
      where project_id=?
      order by id desc
    """, (pid,)).fetchall()

    lines = []
    lines.append(f"# {pname}")
    lines.append("")
    lines.append(desc)
    lines.append("")
    lines.append(f"Generated: {now()}")
    lines.append("")
    for typ in ["task", "decision", "note", "source"]:
        lines.append(f"## {typ.title()}s")
        found = False

        for r in items:
            item_type, item_id, title, body, url, status, created = r
            if item_type != typ:
                continue

            found = True
            lines.append(f"- [{item_id}] **{status}** {created}: {title}")
            if body:
                lines.append(f"  - {body}")
            if url:
                lines.append(f"  - {url}")

        if not found:
            lines.append("- none")

        lines.append("")

    lines.append("## Linked Artifacts")
    if not links:
        lines.append("- none")

    for artifact_id, note, created in links:
        a = artifact_summary(artifact_id)
        if a:
            lines.append(f"- Artifact {a[0]} / {a[1]}: {a[3]}")
            lines.append(f"  - {note or a[4]}")
        else:
            lines.append(f"- Artifact {artifact_id}: {note}")

    path.write_text("\n".join(lines))

    art = BASE / "holy_artifact.py"
    if art.exists():
        subprocess.run(
            ["/usr/local/bin/python3", str(art), "add", "kb-report", str(path), f"KB report project={pname}"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )

    print(f"KB_REPORT={path}")

def dispatch(args):
    if not args:
        print("Usage: init|project-add|projects|note|task|decision|source|done|link-artifact|project|search|next|report")
        return 2

    cmd, rest = args[0], args[1:]

    if cmd == "init": return init(rest) or 0
    if cmd == "project-add": return project_add(rest) or 0
    if cmd in ("projects", "project-list"): return projects(rest) or 0
    if cmd == "note": return add_item(rest, "note") or 0
    if cmd == "task": return add_item(rest, "task") or 0
    if cmd == "decision": return add_item(rest, "decision") or 0
    if cmd == "source": return source(rest) or 0
    if cmd == "done": return done(rest) or 0
    if cmd == "link-artifact": return link_artifact(rest) or 0
    if cmd == "project": return project_view(rest) or 0
    if cmd == "search": return search(rest) or 0
    if cmd == "next": return next_tasks(rest) or 0
    if cmd == "report": return report(rest) or 0

    print(f"Unknown kb command: {cmd}")
    return 2

def main():
    if len(sys.argv) >= 2 and sys.argv[1] == "rpc":
        payload = json.loads(sys.stdin.read())
        return dispatch(payload.get("args", []))
    return dispatch(sys.argv[1:])

if __name__ == "__main__":
    raise SystemExit(main())
