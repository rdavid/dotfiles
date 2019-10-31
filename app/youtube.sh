#!/bin/sh
NME='youtube'
LOG="/tmp/$NME.log"
LCK="/tmp/$NME.lck"

# Prevents multiple instances.
if [ -e "$LCK" ] && kill -0 "$(cat "$LCK")"; then
  echo "$0 is already running."
  exit 0
fi

log() {
  date +"%Y%m%d-%H:%M:%S $*" | tee -a "$LOG"
}

# Makes sure the lockfile is removed when we exit and then claim it.
# shellcheck disable=SC2064
trap "rm -f $LCK" INT TERM EXIT
echo $$ > "$LCK"
echo | tee -a "$LOG"
log "Start $NME."
youtube-dl \
  --playlist-reverse \
  --download-archive /media/data/app/box/youtube/done.txt \
  -i -o \
  "/media/data/app/box/done/%(uploader)s/e%(playlist_index)s-%(title)s.%(ext)s" \
  -f bestvideo[ext=mp4]+bestaudio[ext=m4a] \
  --merge-output-format mp4 \
  --add-metadata \
  --write-thumbnail \
  --batch-file=/media/data/app/box/youtube/channels.txt \
  2>&1 | tee -a "$LOG"
log "Done $NME."
exit 0
