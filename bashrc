# shellcheck shell=sh
# vi: lbr noet sw=2 ts=2 tw=79 wrap
# SPDX-FileCopyrightText: 2016-2026 David Rabkin
# SPDX-License-Identifier: 0BSD
#
# Configures interactive Bash sessions by loading the aliases and functions,
# setting the environment, and enabling vi editing.
#
# Files are not following:
#  shellcheck disable=SC1090,SC1091
. "$HOME/dotfiles/aliases"
. "$HOME/dotfiles/functions"

# Sets the pager, editor, and history defaults.
export EDITOR=vim \
	HISTCONTROL=ignoreboth \
	HISTFILESIZE=32768 \
	HISTSIZE=32768 \
	PAGER=most \
	VISUAL=vim

# Tells GnuPG which terminal to use for passphrase prompts.
GPG_TTY="$(tty)"
export GPG_TTY

# Puts the MacPorts and local directories ahead of the system ones.
PATH=/opt/local/bin:/usr/local/bin:$PATH

# Enables vi editing on the command line.
set -o vi

# Loads the fzf key bindings when present.
[ -f ~/.fzf.bash ] && . ~/.fzf.bash
