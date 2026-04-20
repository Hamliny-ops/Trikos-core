#!/usr/bin/env bash

echo "[CORE] Building clean engine..."

cat > ~/trikos/core/core_engine.py << 'EOF'

from core.trikos import parse, energy, step


def run(expr, it=10):

    # input handling
    try:
        it = int(it)
    except:
        it = 10

    nodes = parse(expr)

    print("[core] expression:", expr)
    print("[core] initial energy:", round(energy(nodes), 4))

    for i in range(it):
        step(nodes)
        e = energy(nodes)
        print(f"ITER {i} | Energy:", round(e, 4))

    return nodes

EOF

echo "[✓] Engine linked"
