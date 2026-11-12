# shellcheck shell=sh
# vi: lbr noet sw=2 ts=2 tw=79 wrap
# SPDX-FileCopyrightText: 2016-2026 David Rabkin
# SPDX-License-Identifier: 0BSD
#
# Configures interactive Bash sessions by loading the aliases and functions,
# setting the environment, and enabling vi editing.
#
# The sourced files are not followed:
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

# Moves the Homebrew Ruby, MacPorts, and local directories ahead of the system
# ones, so gem scripts such as rubocop run under Homebrew Ruby rather than the
# macOS system Ruby. Then adds the gem directory unless it is already there.
for d in \
	/usr/local/bin \
	/opt/local/bin \
	/opt/homebrew/opt/ruby/bin \
	/usr/local/opt/ruby/bin; do
	[ -d "$d" ] || continue
	PATH=$d$(printf ':%s:' "$PATH" | sed "s|:$d:|:|g; s|:$||")
done
command -v gem >/dev/null 2>&1 && {
	d=$(gem environment gemdir)/bin
	case :$PATH: in
	*:"$d":*) ;;
	*) PATH=$d:$PATH ;;
	esac
}
unset d

# Enables vi editing on the command line.
set -o vi

# Loads the fzf key bindings when present.
[ -f ~/.fzf.bash ] && . ~/.fzf.bash
