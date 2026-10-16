from board import Board
from ai import AI


class Battleship:
    def __init__(self):
        self.player = Board()
        self.enemy = Board()
        self.ai = AI(size=Board.SIZE)
        self._setup()

    def _setup(self):
        # Setup multiple ships using consistent 0-indexed coordinates
        # Player fleet
        self.player.place_ship({(0, 0), (0, 1), (0, 2)})  # Length 3
        self.player.place_ship({(2, 3), (3, 3)})          # Length 2

        # Enemy fleet
        self.enemy.place_ship({(1, 1), (1, 2), (1, 3)})   # Length 3
        self.enemy.place_ship({(4, 1), (4, 2)})           # Length 2

    def show(self):
        print(f"\nEnter row,col (1-{Board.SIZE}). Type 'q' to quit.")
        print(f"Enemy ship cells remaining: {self.enemy.remaining_cells}")

    def run(self):
        print("=== Battleship ===")
        while True:
            self.show()
            raw = input("> ").strip().lower()
            if raw == "q":
                print("Game quit.")
                return

            try:
                r, c = map(int, raw.split(","))
                pos = (r - 1, c - 1)
            except ValueError:
                print("Invalid format. Use row,col (e.g. 2,3).")
                continue

            if not (0 <= pos[0] < Board.SIZE and 0 <= pos[1] < Board.SIZE):
                print("Outside board boundaries.")
                continue

            # Check enemy board shots, not player board shots
            if pos in self.enemy.shots:
                print("Already fired there.")
                continue

            # Player turn execution
            hit, sunk = self.enemy.fire(pos)
            if sunk:
                print(f"[{r},{c}] HIT! You sunk an enemy ship!")
            elif hit:
                print(f"[{r},{c}] HIT!")
            else:
                print(f"[{r},{c}] MISS!")

            if self.enemy.all_sunk():
                print("\nYou sank the entire enemy fleet! You win!")
                return

            # AI turn execution
            ai_pos = self.ai.choose()
            if ai_pos is None:
                print("AI has no valid shots remaining.")
                continue

            ai_r, ai_c = ai_pos[0] + 1, ai_pos[1] + 1
            ai_hit, ai_sunk = self.player.fire(ai_pos)
            self.ai.register_result(ai_pos, ai_hit)

            if ai_sunk:
                print(f"AI fired at {ai_r},{ai_c} -> HIT! The AI sunk your ship!")
            elif ai_hit:
                print(f"AI fired at {ai_r},{ai_c} -> HIT!")
            else:
                print(f"AI fired at {ai_r},{ai_c} -> MISS!")

            if self.player.all_sunk():
                print("\nThe AI sank your fleet! Game over.")
                return