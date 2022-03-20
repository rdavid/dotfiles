# vi:et lbr noet sw=2 ts=2 tw=79 wrap
# Copyright 2016-2022 David Rabkin

source "$HOME/dotfiles/aliases"
source "$HOME/dotfiles/functions"

export PAGER=most
export VISUAL=vim
export EDITOR=vim
export HISTSIZE='32768';
export HISTFILESIZE="${HISTSIZE}";
export HISTCONTROL='ignoreboth';

GPG_TTY="$(tty)"
export GPG_TTY

PATH=/opt/local/bin:/usr/local/bin:$PATH

# Switches on vi command-line editing.
set -o vi

[ -f ~/.fzf.bash ] && source ~/.fzf.bash
