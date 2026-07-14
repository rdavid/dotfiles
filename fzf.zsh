# shellcheck shell=sh
# vi: lbr noet sw=2 ts=2 tw=79 wrap
# SPDX-FileCopyrightText: 2026 David Rabkin
# SPDX-License-Identifier: 0BSD
#
# Loads fzf completion and key bindings into Zsh from the directory that
# zshrc detects into FZF_PATH. Stays silent when the detection failed,
# since zshrc already reports it.
#
# Files are not following:
#  shellcheck disable=SC1091
[ -d "$FZF_PATH" ] || return 0
case $- in
*i*)
	. "$FZF_PATH"/completion.zsh 2>/dev/null
	;;
esac
. "$FZF_PATH"/key-bindings.zsh
