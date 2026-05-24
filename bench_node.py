import hashlib
import os
import platform
import tempfile
import time

print("BENCH_BEGIN")
print(f"host={platform.node()}")
print(f"python={platform.python_version()}")
print(f"platform={platform.platform()}")

start = time.time()
data = b"holy-cluster" * 10000
digest = b""

for i in range(150000):
    digest = hashlib.sha256(data + str(i).encode()).digest()

cpu_seconds = time.time() - start

print(f"cpu_hash_seconds={cpu_seconds:.3f}")
print(f"cpu_hash_digest={digest.hex()[:16]}")

path = os.path.join(tempfile.gettempdir(), "holy_cluster_disk_test.bin")
block = os.urandom(1024 * 1024)

start = time.time()

with open(path, "wb") as f:
    for _ in range(64):
        f.write(block)
    f.flush()
    os.fsync(f.fileno())

write_seconds = time.time() - start
mb_per_sec = 64 / write_seconds if write_seconds > 0 else 0

print(f"disk_write_seconds={write_seconds:.3f}")
print(f"disk_write_mb_per_sec={mb_per_sec:.2f}")

try:
    os.remove(path)
except OSError:
    pass

print("BENCH_END")
