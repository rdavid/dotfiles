#!/bin/sh
# vim: tabstop=2 shiftwidth=2 expandtab textwidth=80 linebreak wrap
# Copyright 2019-present David Rabkin
# The script downloads all new video from pre-configured channels.txt. It
# updates IDs of downloaded files at done.txt. The script coud be ran by a
# cron job. Uses youtube-dl and rsync.

# Exists on any error.
set -e

# The script is ran by cron, the environment is stricked.
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

NME='youtube'
LOG="/tmp/$NME.log"
LCK="/tmp/$NME.lck"
SRC='/mnt/ibx/ytb/app/channels.txt'
ARC='/mnt/ibx/ytb/app/done.txt'
REN='/mnt/ibx/ytb/app/rename.rb'
DST='/mnt/ibx/ytb'
TMP='/tmp/out'

log() {
  date +"%Y%m%d-%H:%M:%S $*" | tee -a "$LOG"
}

# Prevents multiple instances.
if [ -e "$LCK" ] && kill -0 "$(cat "$LCK")"; then
  log "$0 is already running."
  exit 0
fi

# Makes sure the lockfile is removed when we exit and then claim it.
# shellcheck disable=SC2064
trap "rm -f $LCK" INT TERM EXIT
echo $$ > "$LCK"
log "$NME says hi."
mkdir -p "$TMP" || ( log "Unable to create $TMP."; exit 1 )
youtube-dl \
  --playlist-reverse \
  --download-archive "$ARC" \
  -i -o \
  "$TMP/%(uploader)s-%(upload_date)s-%(title)s.%(ext)s" \
  -f bestvideo[ext=mp4]+bestaudio[ext=m4a] \
  --merge-output-format mp4 \
  --add-metadata \
  --batch-file="$SRC" \
  2>&1 | tee -a "$LOG"
$REN -d "$TMP" -a
rsync -zvhr --progress "$TMP/*" "$DST" 2>&1 | tee -a "$LOG"
rm -rf "$TMP"
log "$NME says bye."
exit 0
