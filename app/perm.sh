#!/bin/sh
#
# perm.sh
#
# Copyright 2019-present David Rabkin
#

if [ 0 -eq $# ]; then
  echo "perm.sh <directory name>"
  exit 0·
fi

DIR=$1
if [ ! -d "$DIR" ]; then
  echo "Directory $DIR does not exist."
  exit 0
fi

# Calculates duration time for report.
duration()
{
  dur=`expr $(date +%s) - $1`
  printf "%d:%02d:%02d" \
         `expr $dur / 3600` \
         `expr $dur % 3600 / 60` \
         `expr $dur % 60`
}

read -r -p "Run $DIR, are you sure? [y/N] " res
case "$res" in
  [yY][eE][sS]|[yY])
    # Continues.
    ;;
  *)
    exit 0
    ;;
esac

BEG="$(date +%s)"
chown -R foobar:users "$DIR"
find "$DIR" -type d -exec chmod 755 {} \;
find "$DIR" -type f -exec chmod 644 {} \;
echo "Done in `duration $BEG`."