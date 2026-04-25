#!/usr/bin/env python3
"""Scrape DDR simfiles from a Zenius-i-vanisher category page.

For each song listed in the category, compare the listed "last updated" cell
against the local .sm mtime and download + extract only when the local copy
looks out-of-date. The website's date is rounded ("3.7 months ago"), so a
configurable margin pads the comparison toward more downloads.

Example:
    poetry run python scripts/scrape/scrape_category.py 1709 WORLD --dry-run
"""

import argparse
import io
import re
import sys
import zipfile
from datetime import datetime, timedelta
from pathlib import Path

import requests
from bs4 import BeautifulSoup

BASE = "https://zenius-i-vanisher.com/v5.2"
CATEGORY_URL = BASE + "/viewsimfilecategory.php?categoryid={cid}"
DOWNLOAD_URL = BASE + "/download.php?type=ddrsimfile&simfileid={sid}"

UNIT_DAYS = {"day": 1, "week": 7, "month": 30, "year": 365}
LAST_UPDATE_RE = re.compile(
    r"([0-9]+(?:\.[0-9]+)?)\s+(day|week|month|year)s?\s+ago",
    re.IGNORECASE,
)
EXTRACT_EXT = re.compile(r"\.(sm|ssc|png)$", re.IGNORECASE)


def approx_update_time(text):
    m = LAST_UPDATE_RE.search(text or "")
    if not m:
        return None, ""
    value = float(m.group(1))
    unit = m.group(2).lower()
    return datetime.now() - timedelta(days=value * UNIT_DAYS[unit]), m.group(0)


def parse_category(html):
    soup = BeautifulSoup(html, "html.parser")
    for row in soup.find_all("tr"):
        link = row.find("a", href=re.compile(r"viewsimfile\.php\?simfileid=\d+"))
        if not link:
            continue
        sid_match = re.search(r"simfileid=(\d+)", link["href"])
        if not sid_match:
            continue

        # Drop decoration spans (e.g. <span title="Vid Exist">[V]</span>)
        # before reading the link text.
        for span in link.find_all("span"):
            span.decompose()
        title = link.get_text(strip=True)
        if not title:
            continue

        last_update_dt, last_update_text = approx_update_time(
            row.get_text(separator=" ", strip=True)
        )
        yield {
            "id": sid_match.group(1),
            "title": title,
            "last_update_text": last_update_text,
            "last_update": last_update_dt,
        }


def find_local_song_dir(version_dir, title):
    """Locate the song folder (containing a .sm), with light fuzzy matching."""
    if not version_dir.is_dir():
        return None

    # Try exact match, then with a trailing " /artist" stripped (Zenius
    # sometimes shows "TITLE / ARTIST" on the listing).
    candidates = [title]
    stripped = title.split(" /")[0].strip()
    if stripped and stripped != title:
        candidates.append(stripped)

    seen = set()
    for cand in candidates:
        if cand in seen:
            continue
        seen.add(cand)

        d = version_dir / cand
        if d.is_dir() and any(d.glob("*.sm")):
            return d

        cand_lower = cand.lower()
        for sub in version_dir.iterdir():
            if (
                sub.is_dir()
                and sub.name.lower() == cand_lower
                and any(sub.glob("*.sm"))
            ):
                return sub
    return None


def newest_file_mtime(folder):
    """mtime of the newest file in `folder` (any extension)."""
    latest = None
    for f in folder.iterdir():
        if not f.is_file():
            continue
        m = datetime.fromtimestamp(f.stat().st_mtime)
        if latest is None or m > latest:
            latest = m
    return latest


def effective_margin(song_age_days, base_margin_days, scale=0.10):
    """Allow more slack for older listings (their rounding is coarser)."""
    return max(base_margin_days, song_age_days * scale)


def needs_update(song, version_dir, margin_days):
    folder = find_local_song_dir(version_dir, song["title"])
    if folder is None:
        return True, "no local copy"
    local_mtime = newest_file_mtime(folder)
    if local_mtime is None:
        return True, "folder is empty"
    if song["last_update"] is None:
        return False, f"no remote date; local {local_mtime:%Y-%m-%d}"
    age_days = max(0.0, (datetime.now() - song["last_update"]).total_seconds() / 86400)
    margin = effective_margin(age_days, margin_days)
    threshold = song["last_update"] - timedelta(days=margin)
    if local_mtime >= threshold:
        return False, (
            f"local {local_mtime:%Y-%m-%d} >= remote "
            f"~{song['last_update']:%Y-%m-%d}-{margin:.0f}d"
        )
    return True, (
        f"local {local_mtime:%Y-%m-%d} < remote "
        f"~{song['last_update']:%Y-%m-%d}-{margin:.0f}d"
    )


def download_and_extract(session, song, version_dir):
    url = DOWNLOAD_URL.format(sid=song["id"])
    r = session.get(url, allow_redirects=True, timeout=120)
    r.raise_for_status()
    if r.content[:2] != b"PK":
        raise RuntimeError(
            f"response was not a zip ({len(r.content)} bytes; rate-limited?)"
        )

    with zipfile.ZipFile(io.BytesIO(r.content)) as zf:
        members = [
            m for m in zf.infolist()
            if not m.is_dir()
            and EXTRACT_EXT.search(m.filename)
            and ".." not in Path(m.filename).parts
            and not Path(m.filename).is_absolute()
        ]
        if not members:
            raise RuntimeError("zip contained no .sm/.ssc/.png entries")

        for m in members:
            target = version_dir / m.filename
            target.parent.mkdir(parents=True, exist_ok=True)
            with zf.open(m) as src, open(target, "wb") as dst:
                dst.write(src.read())

        return version_dir / Path(members[0].filename).parts[0]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("category_id", help="Zenius categoryid (URL ?categoryid=...)")
    parser.add_argument("version", help="Folder under --data-dir, e.g. WORLD")
    parser.add_argument("--data-dir", default="./data")
    parser.add_argument("--dry-run", action="store_true",
                        help="List planned downloads without doing them")
    parser.add_argument("--force", action="store_true",
                        help="Re-download every song regardless of date")
    parser.add_argument("--margin-days", type=float, default=30.0,
                        help="Fuzz window around the listed approximate date "
                             "(default 30d). Higher = fewer downloads.")
    parser.add_argument("--only", help="Filter songs by title substring")
    args = parser.parse_args()

    data_dir = Path(args.data_dir).resolve()
    version_dir = data_dir / args.version
    version_dir.mkdir(parents=True, exist_ok=True)

    session = requests.Session()
    session.headers["User-Agent"] = "ddr-bpm-prep-scraper/1.0"

    print(f"GET {CATEGORY_URL.format(cid=args.category_id)}")
    r = session.get(CATEGORY_URL.format(cid=args.category_id), timeout=60)
    r.raise_for_status()

    songs = list(parse_category(r.text))
    if args.only:
        needle = args.only.lower()
        songs = [s for s in songs if needle in s["title"].lower()]

    print(f"  -> {len(songs)} songs in category {args.category_id} "
          f"(target: {version_dir})\n")

    plan = []
    for s in songs:
        if args.force:
            ok, reason = True, "forced"
        else:
            ok, reason = needs_update(s, version_dir, args.margin_days)
        marker = "DL" if ok else " ."
        title = s["title"][:48]
        print(f"  [{marker}] {s['id']:>6}  {title:<48}  {reason}")
        if ok:
            plan.append(s)

    print(f"\n{len(plan)} song(s) need download")
    if args.dry_run or not plan:
        return 0

    failures = 0
    for s in plan:
        print(f"\n-> {s['id']}  {s['title']}")
        try:
            folder = download_and_extract(session, s, version_dir)
            print(f"   extracted to {folder}")
        except Exception as e:
            failures += 1
            print(f"   ! {e}")

    if failures:
        print(f"\n{failures} download(s) failed", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
