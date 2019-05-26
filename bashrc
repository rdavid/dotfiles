# vim: tabstop=2 shiftwidth=2 expandtab textwidth=80 linebreak wrap
#
# Copyright 2016-present David Rabkin

# Launches zsh.
if [ -t 1 ]; then
  exec zsh
fi

source "$HOME/dotfiles/aliases"
source "$HOME/dotfiles/functions"

PATH=/opt/local/bin:$PATH

# Make vim the default editor.
export EDITOR='vim';

# Doesn’t clear the screen after quitting a manual page.
export MANPAGER='less -X';

# Increases Bash history size. Allow 32³ entries; the default is 500.
export HISTSIZE='32768';
export HISTFILESIZE="${HISTSIZE}";

# Omits duplicates and commands that begin with a space from history.
export HISTCONTROL='ignoreboth';

# Highlights section titles in manual pages.
export LESS_TERMCAP_md="${yellow}";


[ -f ~/.fzf.bash ] && source ~/.fzf.bash
