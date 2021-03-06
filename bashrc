# vi:ts=2 sw=2 tw=79 et lbr wrap
# Copyright 2016 by David Rabkin

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
