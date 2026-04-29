from pathlib import Path
from os import getenv
import logging


build_dir = Path(getenv("BUILD_DIR") or "./build")
build_courses_dir = build_dir / "courses"
build_jackets_dir = build_dir / "jackets"
build_simfiles_dir = build_dir / "simfiles"
build_songs_dir = build_dir / "songs"
build_summaries_dir = build_dir / "summaries"
for folder in [
    build_dir,
    build_courses_dir,
    build_jackets_dir,
    build_songs_dir,
    build_simfiles_dir,
    build_summaries_dir,
]:
    if not folder.exists():
        folder.mkdir()

seed_dir = Path(getenv("SEED_DIR") or "./data")
allsongs_file = str(seed_dir / "all_songs.txt")
removed_file = str(seed_dir / "removed.txt")
title_map_file = str(seed_dir / "title_map.csv")
galaxy_brave_courses_file = str(seed_dir / "galaxy_brave_courses.txt")
world_dansp_courses_file = str(seed_dir / "world_dansp_courses.txt")
world_dandp_courses_file = str(seed_dir / "world_dandp_courses.txt")
version_file = str(seed_dir / "version.txt")


log_folder = Path("./log")


def logfile(fname: str = "log.txt") -> str:
    return str(log_folder / fname)


logging.basicConfig(
    filename=logfile(),
    filemode="w",
    format="[%(levelname)s] %(message)s",
    level=logging.INFO,
)
logger = logging.getLogger(__name__)
