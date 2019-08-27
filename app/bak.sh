#!/bin/sh
# vim: tabstop=2 shiftwidth=2 expandtab textwidth=80 linebreak wrap
#
# Copyright 2016-present David Rabkin
#
# bak.sh <arc|box>

LOG='/tmp/bak.log'
LCK="/tmp/$1.lck"
SRC="/home/david/nas-$1/"
DST="/media/usb-bak/bak-$1"

log()
{
  date +"%Y%m%d-%H:%M:%S $*" | tee -a $LOG
}

if [ ! -d "$SRC" ]; then
  log "There is no source directory $SRC."
  exit 1
fi
if [ ! -d "$DST" ]; then
  log "There is no destination directory $DST."
  exit 1
fi

# Prevents multiple instances.
if [ -e "$LCK" ] && kill -0 "$(cat "$LCK")"; then
  log "Backup of $1 is already running."
  exit 0
fi

# Makes sure the lockfile is removed when we exit and then claim it.
# shellcheck disable=SC2064
trap "rm -f $LCK" INT TERM EXIT
echo $$ > "$LCK"
echo | tee -a $LOG
echo "---------- $(date +"%Y%m%d") ----------" | tee -a $LOG
log "Start $SRC->$DST."
rdiff-backup --print-statistics       \
             --terminal-verbosity 4   \
             --preserve-numerical-ids \
             --force \
             "$SRC" "$DST" \
             2>&1 | tee -a "$LOG"
log "Done $SRC->$DST."
exit 0
