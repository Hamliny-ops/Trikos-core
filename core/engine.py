class Engine:
    def __init__(self):
        self.modules = {}

    def register(self, name, func):
        self.modules[name] = func

    def run(self, name, *args):
        if name not in self.modules:
            return f"Module '{name}' not found"
        return self.modules[name](*args)
