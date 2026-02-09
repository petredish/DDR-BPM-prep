#!/bin/bash

CATEGORY_URL="https://zenius-i-vanisher.com/v5.2/viewsimfilecategory.php?categoryid=1709"

HTML=$(curl -s "$CATEGORY_URL")

# Extract each <tr> row as one block (awk collapses multi-line rows to a single line)
echo "$HTML" | sed -n '/<tr>/,/<\/tr>/p' | awk '
  /<tr>/   { in_row=1; row="" }
  in_row   { row = (row == "" ? $0 : row " " $0) }
  /<\/tr>/ { if (in_row) print row; in_row=0 }
' | while read -r RAWROW; do

    # Remove the video-exists span only (use [^<]* so we don't eat the next </span>)
    ROW=$(echo "$RAWROW" | sed 's/<span[^>]*Vid Exist[^>]*>[^<]*<\/span>//g')

    # Extract simfile ID
    ID=$(echo "$ROW" | sed -n 's/.*simfileid=\([0-9]*\).*/\1/p')
    [ -z "$ID" ] && continue

#    echo $ROW

    # Extract title
    TITLE=$(echo "$ROW" | sed -n 's/.*<a[^>]*>\([^<]*\)<\/a>.*/\1/p')
    TITLE=$(echo "$TITLE" | sed 's/&amp;/\&/g')

    # Extract Last Update string (e.g. "11.1 months ago"); grep gets first match with full number
    LAST_UPDATE=$(echo "$ROW" | grep -oE '[0-9][0-9.]* (months|years|weeks|days) ago' | head -1)

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

    echo "$ID | $TITLE | approx last update: $DATE"
done
