#!/bin/sh
#
# Copyright 2019-present David Rabkin

if [ 0 -eq $# ]; then
  echo 'perm.sh <directory name>'
  exit 0
fi
DIR=$1
if [ ! -d "$DIR" ]; then
  echo "Directory $DIR does not exist."
  exit 0
fi

# Calculates duration time for report.
duration()
{
  dur="$(("$(date +%s)" - "$1"))"
  printf "%d:%02d:%02d" \
    $(("$dur" / 3600)) \
    $(("$dur" % 3600 / 60)) \
    $(("$dur" % 60))
}

read -r "Run $DIR, are you sure? [y/N] " res
case "$res" in
  [yY][eE][sS]|[yY])
    # Continues.
    ;;
  *)
    exit 0
    ;;
esac
BEG="$(date +%s)"
chown -R david "$DIR"
find "$DIR" -type d -exec chmod 755 {} \;
find "$DIR" -type f -exec chmod 644 {} \;
echo "Done in $(duration "$BEG")."
