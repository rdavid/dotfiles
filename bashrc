# shellcheck shell=sh
# vi:et lbr noet sw=2 ts=2 tw=79 wrap
# Copyright 2016-2023 David Rabkin
# shellcheck disable=SC1090,SC1091 # File not following.
. "$HOME/dotfiles/aliases"
. "$HOME/dotfiles/functions"
export EDITOR=vim \
	HISTCONTROL=ignoreboth \
	HISTFILESIZE="$HISTSIZE" \
	HISTSIZE=32768 \
	PAGER=most \
	VISUAL=vim
GPG_TTY="$(tty)"
export GPG_TTY
PATH=/opt/local/bin:/usr/local/bin:$PATH

# Switches on vi command-line editing.
set -o vi
[ -f ~/.fzf.bash ] && . ~/.fzf.bash
