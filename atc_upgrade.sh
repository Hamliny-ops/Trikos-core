#!/usr/bin/env bash

echo "[ATC] Rebuilding architecture..."

BASE=~/atc

mkdir -p $BASE/{core,modules,systems,cli,data}

# =========================
# GRAPH
# =========================
cat > $BASE/core/graph.py << 'EOF'
import random

class Node:
    def __init__(self, symbol):
        self.symbol = symbol
        self.links = set()
        self.value = random.random()

    def connect(self, other):
        if other != self:
            self.links.add(other)
EOF

# =========================
# PARSER
# =========================
cat > $BASE/core/parser.py << 'EOF'
from core.graph import Node

def expand(expr):
    stack = []
    current = ""

    i = 0
    while i < len(expr):
        ch = expr[i]

        if ch == "(":
            stack.append(current)
            current = ""

        elif ch == ")":
            group = current
            current = stack.pop()

            j = i + 1
            num = ""
            while j < len(expr) and expr[j].isdigit():
                num += expr[j]
                j += 1

            repeat = int(num) if num else 1
            current += group * repeat
            i = j - 1

        else:
            current += ch

        i += 1

    return current


def parse(expr):
    expr = expand(expr)
    expr = expr.replace(" ", "").replace("→", "")

    nodes = [Node(ch) for ch in expr]

    for i in range(len(nodes)-1):
        nodes[i].connect(nodes[i+1])
        nodes[i+1].connect(nodes[i])

    return nodes
EOF

# =========================
# ENERGY
# =========================
cat > $BASE/core/energy.py << 'EOF'
def energy(nodes):
    E = 0
    for n in nodes:
        if not n.links:
            continue
        avg = sum([l.value for l in n.links]) / len(n.links)
        E += abs(n.value - avg)
    return E
EOF

# =========================
# DYNAMICS
# =========================
cat > $BASE/core/dynamics.py << 'EOF'
def step(nodes, lr=0.3):
    updates = {}

    for n in nodes:
        if not n.links:
            continue

        avg = sum([l.value for l in n.links]) / len(n.links)

        if "∃" in n.symbol:
            updates[n] = n.value + lr * (avg - n.value) * 1.5
        else:
            updates[n] = n.value + lr * (avg - n.value)

    for n in nodes:
        if n in updates:
            n.value = updates[n]
EOF

# =========================
# ENGINE
# =========================
cat > $BASE/core/engine.py << 'EOF'
from core.parser import parse
from core.energy import energy
from core.dynamics import step

def run(expr, it=10):
    nodes = parse(expr)

    print("[ATC] expr:", expr)
    print("[ATC] energy:", round(energy(nodes), 4))

    for i in range(it):
        step(nodes)
        print(f"[ATC] ITER {i}:", round(energy(nodes), 4))

    return nodes
EOF

# =========================
# CLI
# =========================
cat > $BASE/cli/atc << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash

PYTHONPATH=$HOME/atc python -c "
from core.engine import run
run('$1', 10)
"
EOF

chmod +x $BASE/cli/atc

echo "[✓] ATC architecture ready"
