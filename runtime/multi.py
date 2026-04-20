import subprocess
import sys

def run_multi(n, node, args):
    processes = []

    for i in range(n):
        cmd = ["python", "main.py", node] + args
        p = subprocess.Popen(cmd)
        processes.append(p)

    for p in processes:
        p.wait()

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: multi <count> <node> [args...]")
        sys.exit(1)

    count = int(sys.argv[1])
    node = sys.argv[2]
    args = sys.argv[3:]

    run_multi(count, node, args)
