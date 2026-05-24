#!/usr/bin/env python3
import html
import sqlite3
import subprocess
from pathlib import Path
from urllib.parse import parse_qs, urlparse
from http.server import BaseHTTPRequestHandler, HTTPServer

BASE = Path.home() / "holy-cluster"
QUEUE_DB = BASE / "queue" / "holy_queue.db"
ART_DB = BASE / "artifacts" / "artifacts.db"

def rows(db, query, args=()):
    if not db.exists():
        return []
    con = sqlite3.connect(db)
    try:
        return con.execute(query, args).fetchall()
    finally:
        con.close()

def esc(x):
    return html.escape("" if x is None else str(x))

def page():
    jobs = rows(QUEUE_DB, """
        select id,status,created_at,coalesce(started_at,''),coalesce(finished_at,''),coalesce(exit_code,''),command
        from jobs order by id desc limit 20
    """)

    artifacts = rows(ART_DB, """
        select id,type,created_at,path,coalesce(note,'')
        from artifacts order by id desc limit 20
    """)

    job_html = "".join(
        f"<tr><td>{j[0]}</td><td class='{esc(j[1])}'>{esc(j[1])}</td><td>{esc(j[2])}</td><td>{esc(j[5])}</td><td><code>{esc(j[6])}</code></td></tr>"
        for j in jobs
    ) or "<tr><td colspan='5'>No jobs found.</td></tr>"

    art_html = "".join(
        f"<tr><td>{a[0]}</td><td>{esc(a[1])}</td><td>{esc(a[2])}</td><td><code>{esc(a[3])}</code></td><td>{esc(a[4])}</td><td><a href='/open?id={a[0]}'>open</a></td></tr>"
        for a in artifacts
    ) or "<tr><td colspan='6'>No artifacts found.</td></tr>"

    return f"""<!doctype html>
<html>
<head>
<meta charset="utf-8">
<meta http-equiv="refresh" content="10">
<title>Holy-Cluster Dashboard</title>
<style>
body {{
  background:#02060a;
  color:#00ff88;
  font-family:monospace;
  margin:28px;
}}
h1,h2 {{ text-shadow:0 0 12px #00ff88; }}
.panel {{
  border:1px solid #00ff88;
  padding:18px;
  margin-bottom:24px;
  background:rgba(0,30,24,.55);
  box-shadow:0 0 18px rgba(0,255,136,.25);
}}
table {{ width:100%; border-collapse:collapse; }}
td,th {{ border-bottom:1px solid rgba(0,255,136,.25); padding:8px; vertical-align:top; }}
code {{ color:#9ff; }}
a {{ color:#ffcc66; }}
.done {{ color:#00ff88; }}
.failed {{ color:#ff6666; }}
.queued {{ color:#ffcc66; }}
.running {{ color:#00f5ff; }}
.small {{ color:#9ff; }}
</style>
</head>
<body>
<h1>HOLY-CLUSTER DASHBOARD</h1>
<div class="small">CORTEX-11 head node // ARCHIVE-09 worker/archive // UPLINK-iSH controller</div>

<div class="panel">
<h2>Queue</h2>
<table>
<tr><th>ID</th><th>Status</th><th>Created</th><th>Exit</th><th>Command</th></tr>
{job_html}
</table>
</div>

<div class="panel">
<h2>Artifacts</h2>
<table>
<tr><th>ID</th><th>Type</th><th>Created</th><th>Path</th><th>Note</th><th>Action</th></tr>
{art_html}
</table>
</div>

<div class="panel">
<h2>Quick Commands</h2>
<code>holy q list</code><br>
<code>holy artifact list</code><br>
<code>holy job compute 240000</code><br>
<code>holy checkpoint "message"</code>
</div>
</body>
</html>"""

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        parsed = urlparse(self.path)

        if parsed.path == "/open":
            qs = parse_qs(parsed.query)
            artifact_id = qs.get("id", [""])[0]

            if artifact_id.isdigit():
                result = rows(ART_DB, "select path from artifacts where id=?", (int(artifact_id),))
                if result:
                    path = result[0][0]
                    subprocess.run(["open", path])
                    self.send_response(302)
                    self.send_header("Location", "/")
                    self.end_headers()
                    return

            self.send_response(404)
            self.end_headers()
            self.wfile.write(b"artifact not found")
            return

        body = page().encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

def main():
    host = "127.0.0.1"
    port = 8790
    print(f"Holy dashboard running at http://{host}:{port}")
    HTTPServer((host, port), Handler).serve_forever()

if __name__ == "__main__":
    main()
