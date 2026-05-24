#!/bin/sh
set -u
N="${1:-72}"
T="$(date +%Y%m%d_%H%M%S)"
D="$HOME/holy-cluster/renders/mini_$T"
F="$D/frames"
R="/tmp/hc_frames_$T"
A=$((N/4))
AE=$((A-1))
CS=$A
CE=$((N-1))
mkdir -p "$F"
echo "HOLY-CLUSTER MINI RENDER"
echo "frames=$N archive=0-$AE cortex=$CS-$CE out=$D"
START="$(date +%s)"
ssh archive09 "rm -rf '$R'; mkdir -p '$R'; python3 ~/holy-cluster/r.py 0 $AE '$R' ARCHIVE-09 $N" > /tmp/a_render.txt &
PA=$!
/usr/local/bin/python3 ~/holy-cluster/r.py "$CS" "$CE" "$F" CORTEX-11 "$N" > /tmp/c_render.txt &
PC=$!
wait "$PA"
wait "$PC"
scp archive09:"$R"/frame_*.svg "$F"/ >/dev/null 2>&1 || true
END="$(date +%s)"
WALL=$((END-START))
cat > "$D/index.html" <<EOF
<!doctype html><html><head><meta charset="utf-8"><title>Holy Cluster</title>
<style>
body{background:#02060a;color:#00ff88;font-family:monospace;text-align:center}
img{width:92vw;max-width:1100px;border:2px solid #00ff88;box-shadow:0 0 25px #00ff88}
</style></head><body>
<h1>HOLY-CLUSTER ENTITY RENDER</h1>
<p>frames=$N wall=${WALL}s archive=0-$AE cortex=$CS-$CE</p>
<img id="f" src="frames/frame_0000.svg"><p id="l"></p>
<script>
let n=$N,i=0;function p(x){return String(x).padStart(4,'0')}
setInterval(()=>{f.src='frames/frame_'+p(i)+'.svg';l.innerText='frame '+p(i)+'/'+p(n-1);i=(i+1)%n},80)
</script></body></html>
EOF
cat > "$D/report.txt" <<EOF
HOLY-CLUSTER MINI RENDER REPORT
frames=$N
wall_seconds=$WALL
archive_frames=0-$AE
cortex_frames=$CS-$CE
output=$D
ARCHIVE_RESULT=$(cat /tmp/a_render.txt)
CORTEX_RESULT=$(cat /tmp/c_render.txt)
EOF
cat "$D/report.txt"
echo "open_file=$D/index.html"
