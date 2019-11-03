#!/bin/sh
# vim: tabstop=2 shiftwidth=2 expandtab textwidth=80 linebreak wrap
# Copyright 2019-present David Rabkin

# Calculates duration time for report.
duration() {
  dur="$(("$(date +%s)" - "$1"))"
  printf "%d:%02d:%02d" \
    $(("$dur" / 3600)) \
    $(("$dur" % 3600 / 60)) \
    $(("$dur" % 60))
}

if [ 0 -eq $# ]; then
  printf 'perm.sh <directory name>\n'
  exit 0
fi
DIR=$1
if [ ! -d "$DIR" ]; then
  printf 'Directory %s does not exist.\n' "$DIR"
  exit 0
fi
printf 'Run %s, are you sure? [y/N] ' "$DIR"
CFG=$(stty -g)
stty raw -echo; ans=$(head -c 1); stty "$CFG"
if ! echo "$ans" | grep -iq "^y"; then
  printf '\n'
  exit 0
fi
BEG="$(date +%s)"
chown -R david "$DIR"
find "$DIR" -type d -exec chmod 755 {} \;
find "$DIR" -type f -exec chmod 644 {} \;
printf 'Done in %s seconds.\n' "$(duration "$BEG")"
