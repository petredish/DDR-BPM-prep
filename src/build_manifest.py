"""
Build a top-level manifest.json describing every artifact in the GH release.

Run this AFTER predeploy (so songs.zip/jackets.zip exist) and AFTER parse_courses
(so course JSONs exist). The mobile app polls this manifest to decide when to
refresh its local copy of any release artifact.
"""

import hashlib
import re
from datetime import datetime, timezone
from pathlib import Path

import env
import utils


# Artifacts uploaded to the GH release. Order shown is purely for readability.
RELEASE_ARTIFACTS = [
    # Top-level build/
    "songs.zip",
    "jackets.zip",
    "all_songs.txt",
    "removed.txt",
    # build/courses/*.json — flattened in the release upload
    "courses/galaxy_brave.json",
    "courses/world_dan_sp.json",
    "courses/world_dan_dp.json",
]


def hashFile(path: Path) -> str:
    with open(path, "rb") as f:
        return "sha256:" + hashlib.sha256(f.read()).hexdigest()


def resolveVersion(now: datetime) -> str:
    """Resolve the manifest version string.

    Default: today's UTC date as YYYYMMDD (e.g. "20260429").
    Override: if `data/version.txt` exists and is non-empty, use its trimmed
    contents verbatim (must still be 8 digits). Useful when you want to publish
    a release dated for a specific day, or pin a same-day re-release suffix
    convention you manage yourself (e.g. "20260429" → "20260430" if shipped
    after midnight UTC).
    """
    override_path = Path(env.version_file)
    if override_path.exists():
        raw = override_path.read_text().strip()
        if raw:
            if not re.fullmatch(r"\d{8}", raw):
                raise ValueError(
                    f"version override '{raw}' in {override_path} is not YYYYMMDD"
                )
            return raw
    return now.strftime("%Y%m%d")


def main():
    now = datetime.now(timezone.utc)
    version = resolveVersion(now)

    artifacts = {}
    missing = []
    for rel_path in RELEASE_ARTIFACTS:
        path = env.build_dir / rel_path
        if not path.exists():
            missing.append(rel_path)
            continue
        # Use the basename as the manifest key, since the release flattens paths.
        artifacts[path.name] = {"hash": hashFile(path)}

    if missing:
        msg = (
            f"Missing artifacts under {env.build_dir}: {missing}. "
            "Run `make parse` and `make predeploy` before building the manifest."
        )
        env.logger.error(msg)
        print(f"[ERROR] {msg}")
        raise SystemExit(1)

    manifest = {
        "version": version,
        "updated_at": now.isoformat(),
        "artifacts": artifacts,
    }

    out_path = env.build_dir / "manifest.json"
    utils.writeJson(manifest, str(out_path))
    env.logger.info(f"Wrote manifest with {len(artifacts)} artifacts (version {version})")
    print(f"Wrote {out_path} (version {version}, {len(artifacts)} artifacts)")


if __name__ == "__main__":
    main()
