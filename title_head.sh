#!/bin/sh
set -u

TEXT="$(cat "$HOME/holy-cluster/title_text.txt" 2>/dev/null || echo "HOLY-CLUSTER ONLINE")"
N="$(cat "$HOME/holy-cluster/title_frames.txt" 2>/dev/null || echo "96")"

T="$(date +%Y%m%d_%H%M%S)"
D="$HOME/holy-cluster/title_renders/title_$T"
F="$D/frames"
R="/tmp/hc_title_$T"

A=$((N / 4))
AE=$((A - 1))
CS=$A
CE=$((N - 1))

mkdir -p "$F"

echo "HOLY-CLUSTER TITLE RENDER"
echo "text=$TEXT"
echo "frames=$N archive=0-$AE cortex=$CS-$CE"

START="$(date +%s)"

ssh archive09 "rm -rf '$R'; mkdir -p '$R'; python3 ~/holy-cluster/title_worker.py 0 $AE '$R' ARCHIVE-09 $N '$TEXT'" > /tmp/title_archive.txt &
PA=$!

/usr/local/bin/python3 ~/holy-cluster/title_worker.py "$CS" "$CE" "$F" CORTEX-11 "$N" "$TEXT" > /tmp/title_cortex.txt &
PC=$!

wait "$PA"
wait "$PC"

scp archive09:"$R"/frame_*.svg "$F"/ >/dev/null 2>&1 || true

END="$(date +%s)"
WALL=$((END - START))

cat > "$D/index.html" <<EOF
<!doctype html><html><head><meta charset="utf-8"><title>Holy Title</title>
<style>
body{margin:0;background:#02060a;color:#00ff88;font-family:monospace;text-align:center}
img{width:100vw;height:auto}
</style></head><body>
<img id="f" src="frames/frame_0000.svg">
<script>
let n=$N,i=0;function p(x){return String(x).padStart(4,"0")}
setInterval(()=>{f.src="frames/frame_"+p(i)+".svg";i=(i+1)%n},70)
</script></body></html>
EOF

cat > "$D/report.txt" <<EOF
HOLY-CLUSTER TITLE REPORT
text=$TEXT
frames=$N
wall_seconds=$WALL
archive_frames=0-$AE
cortex_frames=$CS-$CE
output=$D
$(cat /tmp/title_archive.txt)
$(cat /tmp/title_cortex.txt)
EOF

/usr/local/bin/python3 "$HOME/holy-cluster/holy_artifact.py" add title "$D/index.html" "title render text=$TEXT frames=$N wall=${WALL}s" 2>/dev/null || true
cat "$D/report.txt"
echo "open_file=$D/index.html"
