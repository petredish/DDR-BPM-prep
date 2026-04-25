import env

import json
import os
import sys
import datetime

_script_dir = os.path.dirname(os.path.abspath(__file__))
_proj_root = os.path.dirname(_script_dir)
DEBUG_LOG = os.path.join(_proj_root, ".cursor", "debug.log")


def _debug_log(message: str, data: dict) -> None:
    try:
        if os.path.isdir(os.path.dirname(DEBUG_LOG)):
            with open(DEBUG_LOG, "a") as f:
                f.write(
                    json.dumps(
                        {
                            "timestamp": int(datetime.datetime.now().timestamp() * 1000),
                            "location": "generate_dat.py:main",
                            "message": message,
                            "data": data,
                            "hypothesisId": "H_gen_dat",
                        }
                    )
                    + "\n"
                )
    except Exception:
        pass


def main():
    source = env.seed_dir / sys.argv[1]  # e.g. data/A20
    outfile = source / f"{sys.argv[1]}.dat"

    records = []
    for folder in sorted(os.listdir(source)):
        folder_path = os.path.join(source, folder)
        is_dir = os.path.isdir(folder_path)

        if not is_dir:
            continue

        # Require at least one simfile (.sm or .ssc) so non-song dirs are skipped,
        # but compute the date from the most recently updated file in the folder.
        has_simfile = False
        mtimes: list[float] = []
        for entry in os.listdir(folder_path):
            full_path = os.path.join(folder_path, entry)
            if not os.path.isfile(full_path):
                continue
            if entry.endswith(".sm") or entry.endswith(".ssc"):
                has_simfile = True
            try:
                mtimes.append(os.path.getmtime(full_path))
            except OSError:
                continue

        if not has_simfile or not mtimes:
            # #region agent log
            _debug_log(
                "generate_dat skip (no simfile / no files)",
                {"folder": folder, "entries": os.listdir(folder_path)},
            )
            # #endregion
            continue

        mtime = max(mtimes)
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