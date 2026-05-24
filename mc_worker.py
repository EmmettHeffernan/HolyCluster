import hashlib, multiprocessing as mp, platform, sys, time

def work(args):
    loops, seed = args
    data = b"holy-cluster-multicore" * 10000
    d = b""
    for i in range(loops):
        d = hashlib.sha256(data + str(seed).encode() + str(i).encode()).digest()
    return d.hex()[:16]

def main():
    total = int(sys.argv[1])
    node = sys.argv[2]
    workers = int(sys.argv[3])

    base = total // workers
    jobs = []
    for i in range(workers):
        loops = base if i < workers - 1 else total - base * (workers - 1)
        jobs.append((loops, i))

    start = time.time()
    with mp.Pool(processes=workers) as pool:
        digests = pool.map(work, jobs)
    sec = time.time() - start
    rate = total / sec if sec else 0

    print(f"node={node}")
    print(f"host={platform.node()}")
    print(f"python={platform.python_version()}")
    print(f"workers={workers}")
    print(f"loops={total}")
    print(f"seconds={sec:.3f}")
    print(f"rate={rate:.2f}")
    print(f"digest={''.join(digests)[:16]}")

if __name__ == "__main__":
    main()
