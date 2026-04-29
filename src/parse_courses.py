import env
import utils
from build_tools import writeCourseToDist


VALID_DIFFS = {"beginner", "basic", "difficult", "expert", "challenge"}


def parseSongLineWithDiffWord(line):
    """Format: 'Song Name,difficulty' — e.g. 'RED ZONE,beginner'

    Difficulty is preserved verbatim (one of beginner|basic|difficult|expert|challenge).
    The mobile app translates to the per-song chart-key vocabulary at render time.
    """
    name, diff = line.rsplit(",", maxsplit=1)
    diff_word = diff.strip().lower()
    if diff_word not in VALID_DIFFS:
        raise ValueError(f"Unknown difficulty '{diff_word}' in line: {line!r}")
    return {"name": name.strip(), "diff": diff_word}


def parseGalaxyBraveCourse(chunk):
    """First line = course title, remaining lines = song names (no difficulty)."""
    return {
        "name": chunk[0],
        "songs": [{"name": name} for name in chunk[1:]],
    }


def parseWorldDanCourse(chunk, spDp):
    """First line = rank title, remaining lines = 'Name,difficulty'."""
    assert spDp in ("sp", "dp")
    return {
        "spDp": spDp,
        "name": chunk[0],
        "songs": [parseSongLineWithDiffWord(line) for line in chunk[1:]],
    }


def parseCourseFile(filename: str) -> list:
    """Split file into chunks separated by blank lines."""
    chunks = []
    chunk = []
    with open(filename, "r") as file:
        for line in file:
            if stripped := line.strip():
                chunk.append(stripped)
            elif chunk:
                chunks.append(chunk)
                chunk = []
        if chunk:
            chunks.append(chunk)
    return chunks


def validateCourseSongs(courses, summary, label):
    """Warn for any course song name not found in summary. Returns list of misses."""
    summary_names = {s["name"].lower() for s in summary}
    missing = []
    for course in courses:
        for song in course["songs"]:
            if song["name"].lower() not in summary_names:
                missing.append((course["name"], song["name"]))
    if missing:
        env.logger.warning(f"[{label}] {len(missing)} unmatched song(s):")
        for course_name, song_name in missing:
            env.logger.warning(f"  {course_name!r} -> {song_name!r}")
            print(f"[WARN] {label}: {course_name!r} references unknown song {song_name!r}")
    else:
        env.logger.info(f"[{label}] all songs resolved against summary.json")
    return missing


def main():
    galaxy = [parseGalaxyBraveCourse(c) for c in parseCourseFile(env.galaxy_brave_courses_file)]
    world_sp = [parseWorldDanCourse(c, "sp") for c in parseCourseFile(env.world_dansp_courses_file)]
    world_dp = [parseWorldDanCourse(c, "dp") for c in parseCourseFile(env.world_dandp_courses_file)]

    summary_path = env.build_summaries_dir / "summary.json"
    if summary_path.exists():
        summary = utils.readJson(str(summary_path))
        validateCourseSongs(galaxy, summary, "galaxy_brave")
        validateCourseSongs(world_sp, summary, "world_dan_sp")
        validateCourseSongs(world_dp, summary, "world_dan_dp")
    else:
        env.logger.warning(
            f"{summary_path} not found — skipping song-name validation. "
            "Run `make songs` first to generate it."
        )
        print(f"[WARN] {summary_path} not found — skipping song-name validation.")

    writeCourseToDist(galaxy, "galaxy_brave")
    writeCourseToDist(world_sp, "world_dan_sp")
    writeCourseToDist(world_dp, "world_dan_dp")
    return galaxy, world_sp, world_dp


if __name__ == "__main__":
    main()
