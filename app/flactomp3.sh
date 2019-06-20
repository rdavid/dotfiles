#!/bin/sh
#
# Copyright 2019-present David Rabkin

FLAC_FILE="$1"
MP3_FILE="`echo ${FLAC_FILE} | sed 's/\.flac/.mp3/'`"
metaflac --export-tags-to=/dev/stdout "${FLAC_FILE}" |
  sed -e 's/=/="/' -e 's/$/"/' \
    -e 's/Album=/ALBUM=/' \
    -e 's/Genre=/GENRE=/' \
    -e 's/Artist=/ARTIST=/' > /tmp/tags-$$
cat /tmp/tags-$$
. /tmp/tags-$$
rm /tmp/tags-$$
flac -dc "${FLAC_FILE}" |
    lame -h -b 320 \
      --tt "${TITLE}" \
      --tn "${TRACKNUMBER}" \
      --ty "${DATE}" \
      --ta "${ARTIST}" \
      --tl "${ALBUM}" \
      --tg "${GENRE}" \
      --add-id3v2 /dev/stdin "${MP3_FILE}"
