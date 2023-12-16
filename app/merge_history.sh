#!/bin/sh -eu
# vi:ts=2 sw=2 tw=79 et lbr wrap
# Copyright 2018-2023 David Rabkin
# Magic, do not touch. See:
#   https://david-kerwick.github.io/2017-01-04-combining-zsh-history-files/
# shellcheck disable=SC2026 # This word is outside of quotes.
cat "$@" | awk -v date="WILL_NOT_APPEAR$(date +"%s")" '{if (sub(/\\$/,date)) printf "%s", $0; else print $0}' | LC_ALL=C sort -u | awk -v date="WILL_NOT_APPEAR$(date +"%s")" '{gsub('date',"\\\n"); print $0}'
