import sys
from core.mesh import Mesh
from modules.example import hello
from modules.run import run

mesh = Mesh()

mesh.register_node("hello", hello)
mesh.register_node("run", run)

# kopplingar (mesh routes)
mesh.connect("hello", "run")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: trikos <node>")
        sys.exit(1)

    node = sys.argv[1]
    args = sys.argv[2:]

    result = mesh.run(node, *args)
    print(result)
