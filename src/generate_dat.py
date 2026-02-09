
import env

import os
import sys
import datetime



def main():
    source = env.seed_dir / sys.argv[1]  # e.g. data/A20
    outfile = source / f"{sys.argv[1]}.dat"

    records = []
    for folder in sorted(os.listdir(source)):
        folder_path = os.path.join(source, folder)

        if not os.path.isdir(folder_path):
            continue

        sm_file = None
        for entry in os.listdir(folder_path):
            if entry.endswith(".sm"):
                sm_file = os.path.join(folder_path, entry)
                break

        if not sm_file:
            continue

        mtime = os.path.getmtime(sm_file)
        date_str = datetime.datetime.fromtimestamp(mtime).strftime("%Y-%m-%d")

        records.append(f"{folder},{date_str}")

    with open(outfile, "w") as f:
        for r in records:
            f.write(r + "\n")
        f.write(f"TRAILER,{len(records)}\n")

def main2():
    source = env.seed_dir/sys.argv[1]  # e.g. data/A20
    outfile = source / f"{sys.argv[1]}.dat"
    print(source)
    print(outfile)


if __name__ == "__main__":
    main()