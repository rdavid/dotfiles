# vim: tabstop=2 shiftwidth=2 expandtab textwidth=80 linebreak wrap
#
# zshrc
#
# Copyright 2016-present David Rabkin

# Cool man pager, viewer and editor.
export PAGER=most
export VISUAL=vim
export EDITOR=vim
export HISTCONTROL=ignorespace

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"
export ZSH_THEME="wezm"

# Uncomment the following line to change how often to auto-update (in days).
export UPDATE_ZSH_DAYS=30

# Uncomment the following line to display red dots whilst waiting for completion.
COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
HIST_STAMPS="yyyy-mm-dd"

# Which plugins would you like to load? (plugins can be found in
# ~/.oh-my-zsh/plugins/*). Custom plugins may be added to
# ~/.oh-my-zsh/custom/plugins/. Example format: plugins=(git textmate ruby)
# Add wisely, as too many plugins slow down shell startup.
plugins=( \
  archlinux battery brew catimg colored-man-pages colorize common-aliases \
  compleat debian docker docker-compose gem git git-extras git-flow github \
  golang history lol osx pip python rsync ruby sudo tmux vi-mode \
  web-search yarn z \
)

# User configuration.
export PATH='/opt/local/bin/:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin'
export PATH="$HOME/.gem/ruby/2.5.0/bin:$PATH"
export PATH="/usr/local/go/bin:$PATH"
export PATH="/usr/local/opt/ruby/bin:$PATH"
export PATH="$HOME/dotfiles/app:$PATH"

# Corrects work of tmuxp.
export PATH="`python -m site --user-base`/bin":$PATH
export GOPATH="$HOME/src/go"
source "$HOME/dotfiles/app/z.sh"
source "$ZSH/oh-my-zsh.sh"
source "$HOME/dotfiles/aliases"
source "$HOME/dotfiles/functions"
alias src="source $HOME/.zshrc"
case $(uname -a) in
  *Microsoft*)
    unsetopt BG_NICE
    MC='/usr/lib/mc/mc-wrapper.sh'
    ;;
  *)
    case "$OSTYPE" in
      darwin*)
        MC='/usr/local/Cellar/midnight-commander/4.8.22/libexec/mc/mc-wrapper.sh'
        export DISPLAY=:0
        export LC_ALL=en_US.UTF-8
        export LANG=en_US.UTF-8
        ;;
      linux*)
        MC='/usr/lib/mc/mc-wrapper.sh'
        export DISPLAY=:0
        export LC_ALL=en_US.UTF-8
        export LANG=en_US.UTF-8
        export PATH="/home/linuxbrew/.linuxbrew/bin:$PATH"
        export MANPATH="/home/linuxbrew/.linuxbrew/share/man:$MANPATH"
        export INFOPATH="/home/linuxbrew/.linuxbrew/share/info:$INFOPATH"
        ;;
      freebsd*)
        MC='/usr/local/libexec/mc/mc-wrapper.sh'
        ;;
      openbsd*)
        MC='/usr/local/libexec/mc/mc-wrapper.sh'
        export DISPLAY=:0
        export LC_ALL=en_US.UTF-8
        export LANG=en_US.UTF-8
        alias ls='gls --color'
        ;;
      msys*)
        MC='/usr/lib/mc/mc-wrapper.sh'
        ;;
      *)
        echo "unknown: $OSTYPE"
        ;;
    esac
esac

# Changes last directory of mc into shell.
alias mc=". $MC"
export DISABLE_AUTO_TITLE='true'

# Starts X if installed.
if [[ ! $DISPLAY && $XDG_VTNR -eq 1 ]]; then
  if [[ `which startx` ]]; then
    exec startx
  fi
fi

# Starts tmux.
if [[ "$TERM" != "screen" ]] &&
   [[ -z "$TMUX" ]] &&
   ! test tmux has-session -t main 2>/dev/null; then
  tmuxp load ~/dotfiles/tmux/plugins/tmuxp/main.yaml
else
  # If inside tmux session then print MOTD.
  MOTD=/etc/motd.tcl
  if [ -f $MOTD ]; then
    $MOTD
  fi
fi
