class Board:
    SIZE = 5  # Adjust to 10 if your lab requires a 10x10 board

    def __init__(self):
        # A list of sets, where each element is a distinct ship
        self.ships = []
        # Tracks all coordinates that have been targeted
        self.shots = set()

    def place_ship(self, cells):
        # Append each ship as its own set into the list
        self.ships.append(set(cells))

    @property
    def remaining_cells(self):
        """Calculates unsunk ship cells remaining."""
        total_cells = sum(len(ship) for ship in self.ships)
        hit_cells = sum(len(ship & self.shots) for ship in self.ships)
        return total_cells - hit_cells

    def fire(self, pos):
        """
        Records a shot and returns (hit, sunk):
        - hit: True if pos hits any ship
        - sunk: True if this shot finished off that specific ship
        """
        self.shots.add(pos)
        hit = False
        sunk = False

        for ship in self.ships:
            if pos in ship:
                hit = True
                # If every coordinate of this ship is now in self.shots, it is sunk
                if ship.issubset(self.shots):
                    sunk = True
                break

        return hit, sunk

    def all_sunk(self):
        """Returns True if all ships across the board are destroyed."""
        return self.remaining_cells == 0