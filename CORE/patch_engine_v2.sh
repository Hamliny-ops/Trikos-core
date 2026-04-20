#!/data/data/com.termux/files/usr/bin/bash

FILE=~/trikos/core/core_engine.py
cp "$FILE" "$FILE.bak2"

cat > "$FILE" << 'EOPY'
import random

def mutate(x):
    ops = ["add", "remove", "change"]

    op = random.choice(ops)

    if op == "add":
        return x + random.choice(["a","b","c","1","2"])
    elif op == "remove" and len(x) > 1:
        return x[:-1]
    elif op == "change" and len(x) > 0:
        i = random.randint(0, len(x)-1)
        return x[:i] + random.choice(["a","b","c","1","2"]) + x[i+1:]
    return x

def energy(x):
    return len(x) * 0.1

def run(expr, steps=10, candidates=5):
    state = expr
    best_energy = energy(state)

    print(f"[core] expression: {state}")
    print(f"[core] initial energy: {best_energy:.4f}")

    for i in range(steps):
        pool = []

        for _ in range(candidates):
            new = mutate(state)
            e = energy(new)
            pool.append((new, e))

        pool.sort(key=lambda x: x[1])
        best = pool[0]

        print(f"\nITER {i}")
        for cand, e in pool:
            print(f"  cand: {cand} | E={e:.4f}")

        # 🔥 endast acceptera bättre
        if best[1] < best_energy:
            print(f"→ improved: {best[0]} | E={best[1]:.4f}")
            state = best[0]
            best_energy = best[1]
        else:
            print("→ no improvement (keep state)")

    return state
EOPY

echo "[✓] Engine upgraded (real evolution)"
