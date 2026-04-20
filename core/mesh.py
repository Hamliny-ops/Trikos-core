
import time

class Mesh:
    def __init__(self):
        self.nodes = {}
        self.routes = {}
        self.state = {}

    def register_node(self, name, func):
        self.nodes[name] = func
        self.routes[name] = []

    def connect(self, src, dst):
        self.routes[src].append(dst)

    def run(self, start, *args):
        if start not in self.nodes:
            return f"Node '{start}' not found"

        current = start
        path = [current]
        state = {
            "args": list(args),
            "tick": 0,
            "start_time": time.time()
        }

        while True:
            func = self.nodes[current]

            result = func(state)

            state["tick"] += 1
            state["last"] = result

            if current not in self.routes or not self.routes[current]:
                break

            # branching (väljs i nästa steg)
            current = self.routes[current][0]
            path.append(current)

        elapsed = time.time() - state["start_time"]

        return f"[path: {' -> '.join(path)} | ticks:{state['tick']} | time:{elapsed:.4f}s]\n{state['last']}"
