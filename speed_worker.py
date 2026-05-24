import hashlib
import platform
import sys
import time

loops = int(sys.argv[1])
label = sys.argv[2]

start = time.time()
data = b"holy-cluster-speed-test" * 10000
digest = b""

for i in range(loops):
    digest = hashlib.sha256(data + str(i).encode()).digest()

elapsed = time.time() - start

print(f"node={label}")
print(f"host={platform.node()}")
print(f"python={platform.python_version()}")
print(f"loops={loops}")
print(f"seconds={elapsed:.3f}")
print(f"digest={digest.hex()[:16]}")
