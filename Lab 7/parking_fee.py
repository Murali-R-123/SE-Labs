
RATES = {
    "bike": 10,
    "car": 30,
    "truck": 60
}


def minutes_parked(times):
    # Validate input type
    if not isinstance(times, str):
        return None

    try:
        entry, exit_time = times.strip().split("-")

        h1, m1 = entry.strip().split(":")
        h2, m2 = exit_time.strip().split(":")

        h1, m1 = int(h1), int(m1)
        h2, m2 = int(h2), int(m2)

        # Validate time ranges
        if not (0 <= h1 <= 23 and 0 <= h2 <= 23):
            return None

        if not (0 <= m1 <= 59 and 0 <= m2 <= 59):
            return None

        start = h1 * 60 + m1
        end = h2 * 60 + m2

        # Handle overnight parking
        if end < start:
            end += 24 * 60

        return end - start

    except (ValueError, AttributeError):
        return None


def hourly_rate(vehicle):
    if not isinstance(vehicle, str):
        return None

    vehicle = vehicle.strip().lower()

    return RATES.get(vehicle)


def format_plate(plate):
    if not isinstance(plate, str):
        return None

    p = plate.strip().upper()

    # Validate number plate
    if len(p) != 10 or not p.isalnum():
        return None

    return p[0:2] + " " + p[2:4] + " " + p[4:6] + " " + p[6:10]


def main():
    print("==== Running minutes_parked ====")
    user_input = input("Enter entry and exit time (e.g. 09:30-11:45): ")
    result = minutes_parked(user_input)
    print("Minutes Parked:", result)

    print("\n==== Running hourly_rate ====")
    user_input = input("Enter vehicle type (bike/car/truck): ")
    result = hourly_rate(user_input)
    print("Hourly Rate:", result)

    print("\n==== Running format_plate ====")
    user_input = input("Enter a number plate (e.g. ka01ab1234): ")
    result = format_plate(user_input)
    print("Formatted Plate:", result)


if __name__ == "__main__":
    main()
