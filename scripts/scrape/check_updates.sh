#!/bin/bash

SEED_DIR=${SEED_DIR:-./data}
# Days by which site date must be newer than local to consider "stale" (website approximation can be off by weeks)
STALE_DAYS=${STALE_DAYS:-60}

if  [ $# -ne 2 ]
then
	echo "Input the pack id (contained in the URL as the categoryid, example : https://zenius-i-vanisher.com/v5.2/viewsimfilecategory.php?categoryid=34)";
    exit 1;
else
	ver_id=$1;
	ver_name=$2;
fi

DAT_PATH="$SEED_DIR/$ver_name/$ver_name.dat"
VERSION_DIR="$SEED_DIR/$ver_name"
mkdir -p "$VERSION_DIR"

CATEGORY_URL="https://zenius-i-vanisher.com/v5.2/viewsimfilecategory.php?categoryid=$ver_id"
TITLE_MAP_FILE="$SEED_DIR/title_map.csv"

# Return the folder name used on disk for the given display title (for DAT lookup and path).
# Tries: exact TITLE in DAT, then title_map[TITLE] if in DAT, else TITLE.
resolve_folder() {
	local title="$1"
	if [ -f "$DAT_PATH" ]; then
		if awk -F',' -v f="$title" '$1==f && $2~/^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]$/ { exit 0 } END { exit 1 }' "$DAT_PATH" 2>/dev/null; then
			echo "$title"
			return
		fi
	fi
	if [ -f "$TITLE_MAP_FILE" ]; then
		local mapped
		mapped=$(awk -F',' -v t="$title" 't == $1 { print $2; exit }' "$TITLE_MAP_FILE")
		if [ -n "$mapped" ] && [ -f "$DAT_PATH" ] && awk -F',' -v f="$mapped" '$1==f && $2~/^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]$/ { exit 0 } END { exit 1 }' "$DAT_PATH" 2>/dev/null; then
			echo "$mapped"
			return
		fi
	fi
	echo "$title"
}

# Get the date from DAT for a folder name, or empty if not found.
get_dat_date() {
	local folder="$1"
	[ -f "$DAT_PATH" ] || return
	awk -F',' -v f="$folder" '$1==f && $2~/^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]$/ { print $2; exit }' "$DAT_PATH"
}

# Return 0 if site date is more than STALE_DAYS newer than dat_date (we are stale).
# Uses STALE_DAYS so we can relax threshold when website "last updated" is approximate.
is_stale() {
	local site_date="$1"
	local dat_date="$2"
	[ "$site_date" = "N/A" ] && return 0
	[ -z "$dat_date" ] && return 0
	local site_epoch dat_epoch diff_sec
	site_epoch=$(date -j -f "%Y-%m-%d" "$site_date" +%s 2>/dev/null) || return 0
	dat_epoch=$(date -j -f "%Y-%m-%d" "$dat_date" +%s 2>/dev/null) || return 0
	diff_sec=$(( site_epoch - dat_epoch ))
	[ $diff_sec -gt $(( STALE_DAYS * 86400 )) ]
}

# Download simfile by ID and replace contents of SONG_DIR (restrict to .sm, .ssc, .png).
download_and_replace() {
	local id="$1"
	local song_dir="$2"
	local uri="https://zenius-i-vanisher.com/v5.2/download.php?type=ddrsimfile&simfileid=$id"
	local zip_path
	zip_path=$(mktemp -t "check_updates_zip.XXXXXX")
	if ! curl -sL -J "$uri" -o "$zip_path"; then
		echo "Failed to download $uri" >&2
		rm -f "$zip_path"
		return 1
	fi
	# Replace folder: remove existing contents, unzip to temp, then flatten into SONG_DIR
	rm -rf "$song_dir"
	mkdir -p "$song_dir"
	local tmpdir
	tmpdir=$(mktemp -d -t "check_updates_extract.XXXXXX")
	( unzip -o -q "$zip_path" "*.sm" "*.ssc" "*.png" -d "$tmpdir" 2>/dev/null ) || true
	# Zip often has one root folder; move its contents (or all top-level items) into SONG_DIR
	local first count
	count=0
	for f in "$tmpdir"/*; do
		[ -e "$f" ] || continue
		[ $count -eq 0 ] && first="$f"
		count=$(( count + 1 ))
	done
	if [ "$count" = 1 ] && [ -d "$first" ]; then
		cp -R "$first"/* "$song_dir/" 2>/dev/null || true
	else
		for f in "$tmpdir"/*; do [ -e "$f" ] && cp -R "$f" "$song_dir/" 2>/dev/null || true; done
	fi
	rm -rf "$tmpdir"
	rm -f "$zip_path"
}


HTML=$(curl -s "$CATEGORY_URL")

DOWNLOADED_COUNT=0

# Extract each <tr> row and process in main shell (process substitution) so DAT lookups and downloads work.
while read -r RAWROW; do
    # Remove the video-exists span only (use [^<]* so we don't eat the next </span>)
    ROW=$(echo "$RAWROW" | sed 's/<span[^>]*Vid Exist[^>]*>[^<]*<\/span>//g')

    # Extract simfile ID
    ID=$(echo "$ROW" | sed -n 's/.*simfileid=\([0-9]*\).*/\1/p')
    [ -z "$ID" ] && continue

    # Extract title (normalize &amp; -> &)
    TITLE=$(echo "$ROW" | sed -n 's/.*<a[^>]*>\([^<]*\)<\/a>.*/\1/p')
    TITLE=$(echo "$TITLE" | sed 's/&amp;/\&/g')

    # Extract Last Update string (e.g. "11.1 months ago", "1 year ago")
    LAST_UPDATE=$(echo "$ROW" | grep -oE '[0-9][0-9.]* (month|months|year|years|week|weeks|day|days) ago' | head -1)

    if [ -z "$LAST_UPDATE" ]; then
        DATE="N/A"
    else
        VALUE=$(echo "$LAST_UPDATE" | awk '{print $1}')
        UNIT=$(echo "$LAST_UPDATE" | awk '{print $2}')

        if echo "$UNIT" | grep -q "month"; then
            VALUE_INT=$(printf "%.0f" "$VALUE")
            DATE=$(date -v-"${VALUE_INT}"m +"%Y-%m-%d" 2>/dev/null)
        elif echo "$UNIT" | grep -q "year"; then
            MONTHS=$(printf "%.0f" "$(echo "$VALUE * 12" | bc)")
            DATE=$(date -v-"${MONTHS}"m +"%Y-%m-%d" 2>/dev/null)
        elif echo "$UNIT" | grep -q "week"; then
            DAYS=$(printf "%.0f" "$(echo "$VALUE * 7" | bc)")
            DATE=$(date -v-"${DAYS}"d +"%Y-%m-%d" 2>/dev/null)
        elif echo "$UNIT" | grep -q "day"; then
            DAYS=$(printf "%.0f" "$VALUE")
            DATE=$(date -v-"${DAYS}"d +"%Y-%m-%d" 2>/dev/null)
        else
            DATE="N/A"
        fi

        [ -z "$DATE" ] && DATE="N/A"
    fi

    FOLDER=$(resolve_folder "$TITLE")
    DAT_DATE=$(get_dat_date "$FOLDER")

    if is_stale "$DATE" "$DAT_DATE"; then
        echo "Updating: $TITLE (site: $DATE, local: ${DAT_DATE:-none})"
        if download_and_replace "$ID" "$VERSION_DIR/$FOLDER"; then
            DOWNLOADED_COUNT=$(( DOWNLOADED_COUNT + 1 ))
        else
            echo "  (download failed)" >&2
        fi
    else
        echo "Skip (up to date): $TITLE | $DATE"
    fi
done < <(echo "$HTML" | sed -n '/<tr>/,/<\/tr>/p' | awk '
  /<tr>/   { in_row=1; row="" }
  in_row   { row = (row == "" ? $0 : row " " $0) }
  /<\/tr>/ { if (in_row) print row; in_row=0 }
')

if [ "$DOWNLOADED_COUNT" -gt 0 ]; then
    echo "Downloaded $DOWNLOADED_COUNT song(s). Updating DAT..."
    ( cd "$(dirname "$0")/../.." && python -m src.generate_dat "$ver_name" ) 2>/dev/null || true
fi
