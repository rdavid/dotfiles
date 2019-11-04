#!/bin/sh
# Magic, do not touch, see:
#   https://david-kerwick.github.io/2017-01-04-combining-zsh-history-files/
cat "$@" | awk -v date="WILL_NOT_APPEAR$(date +"%s")" '{if (sub(/\\$/,date)) printf "%s", $0; else print $0}' | LC_ALL=C sort -u | awk -v date="WILL_NOT_APPEAR$(date +"%s")" '{gsub('date',"\\\n"); print $0}'
