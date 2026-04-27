#!/bin/bash
SEED_DIR=${SEED_DIR:-./data}
BUILD_DIR=${BUILD_DIR:-./build}

# Downsize images
jackets_dir=$BUILD_DIR/jackets
mkdir -p $jackets_dir

OIFS="$IFS"
IFS=$'\n'
while IFS= read -r name; do
    [[ -f "$jackets_dir/$name.png" && -z $FORCE ]] && continue

    search_name=$(echo $name | sed -e 's:\[:\\[:g' -e 's:]:\\]:g') # escape square brackets
    png=$(find $SEED_DIR -type f -name "$search_name-jacket.png")
    # Fall back to title_map.csv mapped name (e.g. ".59" -> "59")
    if [[ -z $png ]]; then
        mapped=$(grep "^${name}," $SEED_DIR/title_map.csv | cut -d',' -f2)
        if [[ -n $mapped ]]; then
            search_mapped=$(echo $mapped | sed -e 's:\[:\\[:g' -e 's:]:\\]:g')
            png=$(find $SEED_DIR -type f -name "$search_mapped-jacket.png")
        fi
    fi
    [[ -z $png || ${#png[@]} -eq 0 ]] && echo "$name jacket not found" && exit 1
    [[ ${#png[@]} -gt 1 ]] && echo "Multiple found for $name:\n\t$png" && exit 1

    # Images
    echo Downsizing $name from $png
    magick "$png" -resize 128x128 -quality 100 "$jackets_dir/$name.png"
done < $SEED_DIR/all_songs.txt


# Zip
(cd $BUILD_DIR/songs && zip -r ../songs.zip .)
(cd $jackets_dir && zip -r ../jackets.zip .)

# other files
cp $SEED_DIR/all_songs.txt $SEED_DIR/removed.txt $BUILD_DIR/
