#!/data/data/com.termux/files/usr/bin/bash

FILE=~/trikos/core/core_engine.py

echo "[*] Patching engine: $FILE"

# backup först (viktigt)
cp "$FILE" "$FILE.bak"

# skriv ny engine (ren version)
cat > "$FILE" << 'EOPY'
import random

def mutate(x):
    return x + random.choice(["a", "b", "c", str(random.randint(0,9))])

def energy(x):
    return len(x) * 0.1

def run(expr, steps=10, candidates=5):
    state = expr

    print(f"[core] expression: {state}")
    print(f"[core] initial energy: {energy(state):.4f}")

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

        print(f"→ selected: {best[0]} | E={best[1]:.4f}")

        state = best[0]

    return state
EOPY

echo "[✓] Engine patched"
