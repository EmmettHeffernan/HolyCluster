import hashlib, platform, sys, time

loops=int(sys.argv[1])
node=sys.argv[2]
chunk=sys.argv[3]

data=b"holy-cluster-chunk"*10000
d=b""
t=time.time()

for i in range(loops):
    d=hashlib.sha256(data+str(i).encode()).digest()

s=time.time()-t
rate=loops/s if s else 0

print(f"chunk={chunk}")
print(f"node={node}")
print(f"host={platform.node()}")
print(f"python={platform.python_version()}")
print(f"loops={loops}")
print(f"seconds={s:.3f}")
print(f"rate={rate:.2f}")
print(f"digest={d.hex()[:16]}")
print("---")
