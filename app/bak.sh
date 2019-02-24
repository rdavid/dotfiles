#!/bin/sh
# vim: tabstop=2 shiftwidth=2 expandtab textwidth=80 linebreak wrap
#
# bak.sh
#
# Copyright 2016-present David Rabkin
#
# bak.sh <arc|satashare|hardcopy|nas>
#

LOG="/tmp/bak.log"
LCK="/tmp/$1.lck"
SRC="/home/david/ds-$1/"
DST="/media/usb-$1/bak-$1"

if [ "$1" = "hardcopy" ]; then
  LCK="/tmp/hardcopy.lck"
  SRC="/home/david/ds-arc/apv/"
fi

if [ "$1" = "nas" ]; then
  LOG="/tmp/bak-nas.log"
  LCK="/tmp/nas.lck"
  SRC="/home/david/ds-satashare"
  DST="/home/david/nas-sata"
fi

log()
{
  date +"%Y%m%d-%H:%M:%S $*" | tee -a $LOG
}

if [ ! -d $SRC ]; then
  log "There is no source directory $SRC."
  exit 1
fi

if [ ! -d $DST ]; then
  log "There is no destination directory $DST."
  exit 1
fi

# Prevents multiple instances.
if [ -e $LCK ] && kill -0 `cat $LCK`; then
  log "Backup of $1 is already running."
  exit 0
fi

# Makes sure the lockfile is removed when we exit and then claim it.
trap "rm -f $LCK; exit" INT TERM EXIT
echo $$ > $LCK

echo | tee -a $LOG
echo "---------- $(date +"%Y%m%d") ----------" | tee -a $LOG

log "Start $SRC->$DST."

rdiff-backup --print-statistics       \
             --terminal-verbosity 4   \
             --preserve-numerical-ids \
             --force \
             $SRC $DST \
             2>&1 | tee -a $LOG

rm -f $LCK

log "Done $SRC->$DST."
