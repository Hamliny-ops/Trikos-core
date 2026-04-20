import subprocess
import time

def run(state):
    cmd = " ".join(state["args"])

    start = time.time()
    try:
        out = subprocess.check_output(cmd, shell=True, stderr=subprocess.STDOUT)
        output = out.decode()
    except subprocess.CalledProcessError as e:
        output = e.output.decode()

    duration = time.time() - start

    return f"[tick:{duration:.6f}s]\n{output}"
