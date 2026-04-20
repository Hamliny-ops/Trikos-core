#!/usr/bin/env bash

echo "[ÆGIS] Building TRIKOS language..."

cat > ~/trikos/core/trikos.py << 'EOF'

import random

class Node:
    def __init__(self, symbol):
        self.symbol = symbol
        self.links = set()
        self.value = random.random()

    def connect(self, other):
        if other != self:
            self.links.add(other)

    def __repr__(self):
        return f"{self.symbol}:{round(self.value,2)}"


# =========================
# EXPAND (GRAMMAR)
# =========================

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


# =========================
# PARSE
# =========================

def parse(expr):
    expr = expand(expr)
    expr = expr.replace(" ", "")
    expr = expr.replace("→", "")

    nodes = []

    for ch in expr:
        nodes.append(Node(ch))

    for i in range(len(nodes)-1):
        nodes[i].connect(nodes[i+1])
        nodes[i+1].connect(nodes[i])

    return nodes


# =========================
# ENERGY
# =========================

def energy(nodes):
    E = 0
    for n in nodes:
        if not n.links:
            continue
        avg = sum([l.value for l in n.links]) / len(n.links)
        E += abs(n.value - avg)
    return E


# =========================
# STEP
# =========================

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

echo "[✓] Language ready"
