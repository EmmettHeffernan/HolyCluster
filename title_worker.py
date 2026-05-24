import os, sys, math, time, html

start=int(sys.argv[1])
end=int(sys.argv[2])
out=sys.argv[3]
node=sys.argv[4]
total=int(sys.argv[5])
text=sys.argv[6]

os.makedirs(out, exist_ok=True)
safe=html.escape(text)
t=time.time()

for i in range(start, end+1):
    p=i/max(total-1,1)
    pulse=(math.sin(p*math.pi*2)+1)/2
    shift=math.sin(p*math.pi*4)*18
    glow=int(60+pulse*35)
    color="#00f5ff" if "CORTEX" in node else "#00ff88"

    bars=[]
    for n in range(22):
        h=20+math.sin(p*8+n*.8)*18
        x=70+n*34
        bars.append(f'<rect x="{x}" y="{440-h}" width="18" height="{h}" fill="{color}" opacity=".65"/>')

    svg=f'''<svg xmlns="http://www.w3.org/2000/svg" width="1280" height="720">
<rect width="1280" height="720" fill="#02060a"/>
<rect x="32" y="32" width="1216" height="656" fill="none" stroke="#00ff88" stroke-width="3"/>
<text x="60" y="78" fill="#00ff88" font-family="monospace" font-size="34">HOLY-CLUSTER // TITLE GENERATOR</text>
<text x="60" y="120" fill="#9ff" font-family="monospace" font-size="21">FRAME {i:04d}/{total-1:04d}  NODE={node}</text>
<circle cx="640" cy="270" r="{105+pulse*25}" fill="none" stroke="{color}" stroke-width="3" opacity=".8"/>
<circle cx="640" cy="270" r="{160+pulse*12}" fill="none" stroke="#00ff88" stroke-width="1.5" opacity=".45"/>
<text x="640" y="{300+shift}" fill="{color}" text-anchor="middle" font-family="monospace" font-size="54" font-weight="bold" opacity=".{glow}">{safe}</text>
<text x="640" y="365" fill="#00ff88" text-anchor="middle" font-family="monospace" font-size="24">UPLINK SIGNAL VERIFIED</text>
{''.join(bars)}
<text x="60" y="650" fill="#9ff" font-family="monospace" font-size="20">ARCHIVE-09 LEFT // ENTITY CENTER // CORTEX-11 RIGHT</text>
</svg>'''
    open(os.path.join(out, f"frame_{i:04d}.svg"), "w").write(svg)

print(f"node={node} frames={start}-{end} seconds={time.time()-t:.3f}")
