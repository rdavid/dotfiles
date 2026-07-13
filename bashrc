# shellcheck shell=sh
# vi: lbr noet sw=2 ts=2 tw=79 wrap
# SPDX-FileCopyrightText: 2016-2026 David Rabkin
# SPDX-License-Identifier: 0BSD
#
# Configures interactive Bash sessions.
#
# Files are not following:
#  shellcheck disable=SC1090,SC1091
. "$HOME/dotfiles/aliases"
. "$HOME/dotfiles/functions"
export EDITOR=vim \
	HISTCONTROL=ignoreboth \
	HISTFILESIZE=32768 \
	HISTSIZE=32768 \
	PAGER=most \
	VISUAL=vim
GPG_TTY="$(tty)"
export GPG_TTY
PATH=/opt/local/bin:/usr/local/bin:$PATH

# Switches on vi command-line editing.
set -o vi
[ -f ~/.fzf.bash ] && . ~/.fzf.bash
