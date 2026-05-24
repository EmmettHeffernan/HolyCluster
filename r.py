import os,sys,math,time,random
a=int(sys.argv[1]); b=int(sys.argv[2]); out=sys.argv[3]
node=sys.argv[4]; total=int(sys.argv[5])
os.makedirs(out,exist_ok=True)
is_c="CORTEX" in node
col="#00f5ff" if is_c else "#00ff88"
side="RIGHT / CORTEX-11" if is_c else "LEFT / ARCHIVE-09"
sw=max(1,total//4)
def clamp(x): return max(0,min(1,x))
t0=time.time()
for i in range(a,b+1):
    p=i/max(total-1,1)
    pulse=(math.sin(p*math.pi*2)+1)/2
    hand=clamp(1-abs(i-sw)/7)
    coh=int(52+pulse*38+hand*8)
    gx=math.sin(i*2.7)*hand*5
    eye=5.5+pulse*2+hand*2.5
    gaze=(4 if is_c else -4)+math.sin(p*8)*1.5
    rx=112+pulse*3; ry=148+pulse*5
    state="NODE HANDOFF" if hand>.15 else "SIGNAL STABLE"
    svg=[]
    random.seed(i*9173)
    dots=[]
    for _ in range(125):
        x=random.randint(335,565); y=random.randint(105,385)
        dx=(x-450)/rx; dy=(y-245)/ry
        if dx*dx+dy*dy<1.02:
            r=random.choice([.7,1,1.3])
            op=random.uniform(.18,.8)
            dots.append(f'<circle cx="{x+gx:.1f}" cy="{y}" r="{r}" fill="#00ffcc" opacity="{op:.2f}"/>')
    wires=[]
    for s in [-1,1]:
        for n in range(8):
            y=135+n*25
            x1=450+s*(38+n*5); x2=450+s*(105+n*7)
            wires.append(f'<path d="M{x1+gx:.1f},{y} L{x2+gx:.1f},{y} L{x2+s*18+gx:.1f},{y-10}" fill="none" stroke="#00ff88" stroke-width="1" opacity=".38"/>')
    wave=[]
    for x in range(65,835,22):
        y=430+math.sin(x/42+p*10)*(12+pulse*22+hand*10)
        wave.append(f"{x},{y:.1f}")
    svg.append(f'''<svg xmlns="http://www.w3.org/2000/svg" width="900" height="520">
<defs>
<radialGradient id="skin" cx="50%" cy="45%" r="60%">
<stop offset="0%" stop-color="#00f5ff" stop-opacity=".32"/>
<stop offset="45%" stop-color="#00aa88" stop-opacity=".16"/>
<stop offset="100%" stop-color="#001014" stop-opacity=".03"/>
</radialGradient>
<filter id="g"><feGaussianBlur stdDeviation="2" result="b"/><feMerge><feMergeNode in="b"/><feMergeNode in="SourceGraphic"/></feMerge></filter>
</defs>
<rect width="900" height="520" fill="#02060a"/>
<rect x="20" y="20" width="860" height="480" fill="none" stroke="#00ff88" stroke-width="2"/>
<text x="40" y="56" fill="#00ff88" font-family="monospace" font-size="23">HOLY-CLUSTER // ENTITY INTERFACE</text>
<text x="595" y="56" fill="{col}" font-family="monospace" font-size="15">ACTIVE: {side}</text>
<text x="40" y="88" fill="#9ff" font-family="monospace" font-size="14">FRAME {i:04d}/{total-1:04d} NODE={node} COHERENCE={coh}% STATE={state}</text>''')
    svg.append(f'''<rect x="42" y="118" width="220" height="245" fill="#031014" stroke="#00ff88"/>
<text x="62" y="150" fill="#00ff88" font-family="monospace" font-size="16">LEFT NODE</text>
<text x="62" y="185" fill="#9ff" font-family="monospace" font-size="14">ARCHIVE-09</text>
<text x="62" y="215" fill="#9ff" font-family="monospace" font-size="14">MEMORY BANK</text>
<text x="62" y="245" fill="#9ff" font-family="monospace" font-size="14">WORKER: ONLINE</text>
<text x="62" y="300" fill="#ffcc66" font-family="monospace" font-size="14">FRAME SOURCE:</text>
<text x="62" y="326" fill="{col}" font-family="monospace" font-size="14">{node}</text>
<rect x="638" y="118" width="220" height="245" fill="#031014" stroke="#00ff88"/>
<text x="658" y="150" fill="#00ff88" font-family="monospace" font-size="16">RIGHT NODE</text>
<text x="658" y="185" fill="#9ff" font-family="monospace" font-size="14">CORTEX-11</text>
<text x="658" y="215" fill="#9ff" font-family="monospace" font-size="14">HEAD ENGINE</text>
<text x="658" y="245" fill="#9ff" font-family="monospace" font-size="14">SCHEDULER: ONLINE</text>''')
    svg.append(f'''<g filter="url(#g)" opacity="{.45+pulse*.35+hand*.25:.2f}">
<circle cx="450" cy="250" r="168" fill="none" stroke="#00ff88" stroke-width="1.5"/>
<circle cx="450" cy="250" r="{150+pulse*8:.1f}" fill="none" stroke="#00f5ff" stroke-width="1"/>
</g>
<g filter="url(#g)">
<ellipse cx="{450+gx:.1f}" cy="246" rx="{rx:.1f}" ry="{ry:.1f}" fill="url(#skin)" stroke="#00f5ff" stroke-width="2.4"/>
{''.join(wires)}
{''.join(dots)}
<path d="M{390+gx:.1f},205 C405,191 426,191 441,205" fill="none" stroke="#00ffcc" stroke-width="2"/>
<path d="M{459+gx:.1f},205 C474,191 496,191 511,205" fill="none" stroke="#00ffcc" stroke-width="2"/>
<ellipse cx="{414+gaze+gx:.1f}" cy="224" rx="22" ry="12" fill="#001014" stroke="#00f5ff" stroke-width="1.8"/>
<ellipse cx="{493+gaze+gx:.1f}" cy="224" rx="22" ry="12" fill="#001014" stroke="#00f5ff" stroke-width="1.8"/>
<circle cx="{414+gaze+gx:.1f}" cy="224" r="{eye:.1f}" fill="#00f5ff"/>
<circle cx="{493+gaze+gx:.1f}" cy="224" r="{eye:.1f}" fill="#00f5ff"/>''')
    svg.append(f'''<path d="M{453+gx:.1f},224 C448,245 441,264 431,281 C444,288 462,288 475,281 C464,263 458,244 453,224" fill="none" stroke="#00ffaa" stroke-width="2.2"/>
<path d="M{397+gx:.1f},305 C426,326 481,326 510,305" fill="none" stroke="#00ff88" stroke-width="2.4"/>
<path d="M{413+gx:.1f},306 C438,313 469,313 494,306" fill="none" stroke="#00f5ff" stroke-width="1.2"/>
<line x1="{450+gx:.1f}" y1="95" x2="{450+gx:.1f}" y2="178" stroke="#00f5ff" stroke-width="2"/>
<circle cx="{450+gx:.1f}" cy="120" r="{8+pulse*5+hand*5:.1f}" fill="#00ff88"/>
<circle cx="{450+gx:.1f}" cy="120" r="{18+hand*12:.1f}" fill="none" stroke="#ffcc66" stroke-width="1.5" opacity="{hand:.2f}"/>
</g>''')
    svg.append(f'''<text x="350" y="382" fill="#00ff88" font-family="monospace" font-size="15">"I OBSERVE.  I ANALYZE.  I REMEMBER."</text>
<polyline points="{' '.join(wave)}" fill="none" stroke="{col}" stroke-width="3"/>
<text x="65" y="468" fill="#00ff88" font-family="monospace" font-size="14">SIGNAL WAVEFORM // NODE-SWITCH ANIMATION // CENTER ENTITY DISPLAY</text>
<g opacity="{hand:.2f}">
<rect x="300" y="100" width="300" height="270" fill="none" stroke="#ffcc66" stroke-width="2"/>
<text x="360" y="360" fill="#ffcc66" font-family="monospace" font-size="18">NODE HANDOFF DETECTED</text>
</g>
</svg>''')
    open(os.path.join(out,f"frame_{i:04d}.svg"),"w").write("".join(svg))
print(f"node={node} frames={a}-{b} seconds={time.time()-t0:.3f} out={out}")
