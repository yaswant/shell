#!/bin/bash -e
# date_img imgfile
# rename an image file based on original DateTime
# Yaswant Pradhan
# -----------------------------------------------------------------------------
[[ "$DEBUG" ]] && set -v

[ -f "$1" ] || { echo "usage: ${0##*/} imgfile"; exit 1; }
imgfile="$1"
ext=${imgfile##*.}

cdate=($(identify -verbose "$imgfile" \
    | grep -i 'DateTimeOriginal\|date:modify'))

case $cdate in
    date:modify*)       datetime=${cdate[1]}
                        ;;
    DateTimeOriginal)   datetime=${cdate[@]:1}
                        ;;
esac
ofile="IMG_${datetime}.${ext}"

echo "renaming $imgfile --> $ofile"
mv "$imgfile" "$ofile"
