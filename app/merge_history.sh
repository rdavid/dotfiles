#!/bin/sh -eu
# vi: lbr noet sw=2 ts=2 tw=79 wrap
# SPDX-FileCopyrightText: 2018-2026 David Rabkin
# SPDX-License-Identifier: 0BSD
#
# Merges shell history entries while preserving multiline commands. Joins
# continuation lines with a unique marker, sorts and deduplicates the
# result, then restores the line breaks. The marker is computed once, so
# both awk passes agree on it even across a second boundary. See:
#  https://david-kerwick.github.io/2017-01-04-combining-zsh-history-files/
mrk="WILL_NOT_APPEAR$(date +%s)"
readonly mrk
awk -v mrk="$mrk" '{if (sub(/\\$/, mrk)) printf "%s", $0; else print $0}' \
	"$@" |
	LC_ALL=C sort -u |
	awk -v mrk="$mrk" '{gsub(mrk, "\\\n"); print $0}'
