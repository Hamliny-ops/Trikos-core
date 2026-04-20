#!/data/data/com.termux/files/usr/bin/bash

FILE=~/trikos/core/core_engine.py
cp "$FILE" "$FILE.bak_emergence"

cat > "$FILE" << 'EOPY'
import random

memory = []

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
    # 🔥 3 krafter

    # 1. kompression (kortare bättre)
    e_len = len(x)

    # 2. variation (unika tecken bättre)
    e_var = -len(set(x))

    # 3. minne (straffa repetition)
    penalty = memory.count(x) * 2

    return e_len + e_var + penalty

def select(pool, temperature=0.5):
    # probabilistisk selection (softmax-ish)
    weights = []

    for _, e in pool:
        w = pow(2.718, -e / temperature)
        weights.append(w)

    total = sum(weights)
    r = random.random() * total

    acc = 0
    for i, w in enumerate(weights):
        acc += w
        if acc >= r:
            return pool[i]

    return pool[0]

def run(expr, steps=20, candidates=6):
    state = expr

    print(f"[core] start: {state}")
    print(f"[core] energy: {energy(state):.4f}")

    for i in range(steps):
        pool = []

        for _ in range(candidates):
            new = mutate(state)
            e = energy(new)
            pool.append((new, e))

        pool.sort(key=lambda x: x[1])

        chosen = select(pool, temperature=0.5)

        print(f"\nITER {i}")
        for cand, e in pool:
            print(f"  {cand} | E={e:.4f}")

        print(f"→ chosen: {chosen[0]} | E={chosen[1]:.4f}")

        state = chosen[0]
        memory.append(state)

    return state
EOPY

echo "[✓] Autoemergence engine installed"
