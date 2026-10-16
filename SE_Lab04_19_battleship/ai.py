import random


class AI:
    def __init__(self, size=6):
        self.size = size
        self.tried = set()
        self.targets = []

    def choose(self):
        """Selects the next coordinate to fire at."""
        # 1. Prioritize adjacent target cells queued from previous hits
        while self.targets:
            candidate = self.targets.pop(0)
            if candidate not in self.tried:
                self.tried.add(candidate)
                return candidate

        # 2. Fall back to untried random cells
        options = [
            (r, c)
            for r in range(self.size)
            for c in range(self.size)
            if (r, c) not in self.tried
        ]
        if not options:
            return None  # Safely handles board with no remaining choices

        pos = random.choice(options)
        self.tried.add(pos)
        return pos

    def register_result(self, pos, hit):
        if hit:
            r, c = pos
            neighbors = [(r - 1, c), (r + 1, c), (r, c - 1), (r, c + 1)]
            for nr, nc in neighbors:
                if 0 <= nr < self.size and 0 <= nc < self.size:
                    if (nr, nc) not in self.tried and (nr, nc) not in self.targets:
                        self.targets.append((nr, nc))