import sys
from core.engine import Engine
from modules.example import hello

engine = Engine()
engine.register("hello", hello)

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python main.py <command>")
        sys.exit(1)

    cmd = sys.argv[1]
    args = sys.argv[2:]

    result = engine.run(cmd, *args)
    print(result)
