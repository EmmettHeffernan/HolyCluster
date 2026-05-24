import hashlib, platform, sys, time
loops=int(sys.argv[1]); node=sys.argv[2]
data=b"holy-cluster"*10000
d=b""
t=time.time()
for i in range(loops):
    d=hashlib.sha256(data+str(i).encode()).digest()
s=time.time()-t
print(f"node={node}")
print(f"host={platform.node()}")
print(f"python={platform.python_version()}")
print(f"loops={loops}")
print(f"seconds={s:.3f}")
print(f"rate={loops/s:.2f}")
print(f"digest={d.hex()[:16]}")
