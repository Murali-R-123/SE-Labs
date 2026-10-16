import json
import random
import sqlite3

conn = sqlite3.connect(":memory:")

conn.execute(
    """
    CREATE TABLE songs (
        id INTEGER PRIMARY KEY,
        title TEXT NOT NULL,
        artist TEXT NOT NULL,
        plays INTEGER NOT NULL
    )
    """
)


def add_song(title, artist, plays=0, playlist=None):
    """Add a song to the database and optionally append it to a playlist."""
    if not isinstance(title, str) or not title.strip():
        raise ValueError("title must be a non-empty string")

    if not isinstance(artist, str) or not artist.strip():
        raise ValueError("artist must be a non-empty string")

    if not isinstance(plays, int) or plays < 0:
        raise ValueError("plays must be a non-negative integer")

    if playlist is None:
        playlist = []

    conn.execute(
        "INSERT INTO songs (title, artist, plays) VALUES (?, ?, ?)",
        (title, artist, plays),
    )

    playlist.append(title)
    return playlist


def shuffle_pick():
    """Return a random song ID, or None if no songs exist."""
    song_ids = [
        row[0] for row in conn.execute("SELECT id FROM songs")
    ]

    if not song_ids:
        return None

    return random.choice(song_ids)


def popularity(title):
    """Determine a song's popularity from its play count."""
    row = conn.execute(
        "SELECT plays FROM songs WHERE title = ?",
        (title,),
    ).fetchone()

    if row is None:
        return "unknown"

    return "popular" if row[0] > 100 else "niche"


def save_playlist(playlist):
    """Serialize a playlist of song titles into JSON."""
    if not isinstance(playlist, list) or not all(
        isinstance(title, str) for title in playlist
    ):
        raise ValueError("playlist must be a list of strings")

    return json.dumps(playlist)


def load_playlist(blob):
    """Load and validate a playlist from JSON data."""
    try:
        playlist = json.loads(blob)
    except (json.JSONDecodeError, TypeError) as exc:
        raise ValueError("invalid playlist data") from exc

    if not isinstance(playlist, list) or not all(
        isinstance(title, str) for title in playlist
    ):
        raise ValueError("playlist data must be a JSON list of strings")

    return playlist


def total_plays():
    """Return the total number of plays across all songs."""
    try:
        result = conn.execute(
            "SELECT SUM(plays) FROM songs"
        ).fetchone()
    except sqlite3.Error:
        return 0

    return result[0] if result[0] is not None else 0


def main():
    """Demonstrate the music catalog functionality."""
    playlist = add_song("Aurora", "Nila", 250)
    add_song("Monsoon", "Kavya", 40, playlist)

    blob = save_playlist(playlist)
    loaded_playlist = load_playlist(blob)

    if len(loaded_playlist) > 1:
        print("multi-song playlist")

    print(
        popularity("Aurora"),
        popularity("Monsoon"),
        shuffle_pick(),
        total_plays(),
    )


if __name__ == "__main__":
    main()