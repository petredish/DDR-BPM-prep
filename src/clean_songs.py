"""
Remove songs from all_songs.txt that appear in removed.txt (case-insensitive).
Warns about any remaining case-insensitive duplicates within all_songs.txt.
"""

import env
from collections import Counter


def main():
    with open(env.removed_file) as f:
        removed_lower = set(line.strip().lower() for line in f)

    with open(env.allsongs_file) as f:
        lines = [line.rstrip("\n") for line in f]

    kept = [l for l in lines if l.strip().lower() not in removed_lower]
    dropped = len(lines) - len(kept)

    with open(env.allsongs_file, "w") as f:
        f.write("\n".join(kept) + "\n")

    env.logger.info(f"Removed {dropped} songs from {env.allsongs_file}")

    # warn about case-insensitive duplicates that still remain
    counter = Counter(l.strip().lower() for l in kept if l.strip())
    dupes = {name for name, count in counter.items() if count > 1}
    if dupes:
        env.logger.warning("Case-insensitive duplicates remain in all_songs.txt (manual fix needed):")
        for name in sorted(dupes):
            variants = [l.strip() for l in kept if l.strip().lower() == name]
            env.logger.warning(f"  {variants}")


if __name__ == "__main__":
    main()
