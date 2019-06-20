# vim: tabstop=2 shiftwidth=2 expandtab textwidth=80 linebreak wrap
#
# Copyright 2016-present David Rabkin

source "$HOME/dotfiles/aliases"
source "$HOME/dotfiles/functions"

export PAGER=most
export VISUAL=vim
export EDITOR=vim
export HISTSIZE='32768';
export HISTFILESIZE="${HISTSIZE}";
export HISTCONTROL='ignoreboth';

PATH=/opt/local/bin:/usr/local/bin:$PATH

# Switches on vi command-line editing.
set -o vi

[ -f ~/.fzf.bash ] && source ~/.fzf.bash
