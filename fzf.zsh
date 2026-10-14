# shellcheck shell=sh
# vi: lbr noet sw=2 ts=2 tw=79 wrap
# SPDX-FileCopyrightText: 2026 David Rabkin
# SPDX-License-Identifier: 0BSD
#
# Loads fzf completion and key bindings into Zsh from the directory that zshrc
# stores in FZF_PATH. Stays silent when the detection failed, because zshrc
# already reports it.
#
# The sourced files are not followed:
#  shellcheck disable=SC1091

# Stops when zshrc found no fzf directory.
[ -d "$FZF_PATH" ] || return 0

# Loads the completion in interactive shells only.
case $- in
*i*)
	. "$FZF_PATH"/completion.zsh 2>/dev/null
	;;
esac

# Loads the key bindings.
. "$FZF_PATH"/key-bindings.zsh
