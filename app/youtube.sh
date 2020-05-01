#!/bin/sh
# vim: tabstop=2 shiftwidth=2 expandtab textwidth=80 linebreak wrap
# Copyright 2019-present David Rabkin
# The script downloads all new video from pre-configured acoounts in
# channels.txt. It updates IDs of downloaded files at done.txt. The script
# could be ran by a cron job. Uses youtube-dl, rsync, rename.rb.

# Exists on any error.
set -e

# The script is ran by cron, the environment is stricked.
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

NME='youtube'
LOG="/tmp/$NME.log"
LCK="/tmp/$NME.lck"
SRC='/mnt/nas-ibx/ytb/app/channels.txt'
ARC='/mnt/nas-ibx/ytb/app/done.txt'
REN='/mnt/nas-ibx/ytb/app/rename.rb'
DST='/mnt/nas-ibx/ytb'
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
# Do nothing if the output directory is empty.
# shellcheck disable=SC2010
if ls -1A "$TMP" | grep -q .; then
  $REN -d "$TMP" -a 2>&1 | tee -a "$LOG"
  rsync -zvhr --progress "$TMP"/* "$DST" 2>&1 | tee -a "$LOG"
fi
rm -rf "$TMP"
log "$NME says bye."
exit 0
