#!/usr/bin/env bash

echo "[ATC] Adding asymmetry..."

cat > ~/atc/modules/asymmetry.py << 'EOF'

def apply(nodes):
    for n in nodes:
        if "∃" in n.symbol:
            n.bias = 1.5
        elif "G" in n.symbol:
            n.bias = 1.0
        else:
            n.bias = 0.7

EOF

# patch dynamics
cat > ~/atc/core/dynamics.py << 'EOF'
from modules.asymmetry import apply

def step(nodes, lr=0.3):

    apply(nodes)

    updates = {}

    for n in nodes:
        if not n.links:
            continue

        avg = sum([l.value for l in n.links]) / len(n.links)

        bias = getattr(n, "bias", 1.0)

        updates[n] = n.value + lr * (avg - n.value) * bias

    for n in nodes:
        if n in updates:
            n.value = updates[n]

EOF

echo "[✓] Asymmetry active"
