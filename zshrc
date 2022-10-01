# vi:et lbr noet sw=2 ts=2 tw=79 wrap
# Copyright 2016-2022 David Rabkin

# Cool man pager, viewer and editor.
export PAGER=most
export VISUAL=vim
export EDITOR=vim
export HISTCONTROL='ignoredups'
export HISTIGNORE='make.sh:youtube-dl'
export HIST_STAMPS='yyyy-mm-dd'
export BAT_PAGER=less
export BAT_THEME=zenburn

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"
export ZSH_THEME=minimal

# Uncomment the following line to change how often to auto-update (in days).
export UPDATE_ZSH_DAYS=30

# Uncomment the following line to display red dots whilst waiting for completion.
COMPLETION_WAITING_DOTS='true'

GPG_TTY="$(tty)"
export GPG_TTY

# This is useful if you sometimes type, for example, ‘cd src/bin’ wanting to go
# to ~/src/bin but you aren't in ~.  If the path doesn't exist in the current
# directory, cd will try it in ~ as well.
export CDPATH=:~

# Which plugins would you like to load? (plugins can be found in
# ~/.oh-my-zsh/plugins/*). Custom plugins may be added to
# ~/.oh-my-zsh/custom/plugins/. Example format: plugins=(git textmate ruby)
# Add wisely, as too many plugins slow down shell startup.
plugins=( \
  archlinux battery brew catimg colored-man-pages colorize common-aliases \
  compleat debian docker docker-compose gem git git-extras git-flow github \
  golang history lol macos pip python rsync ruby sudo tmux vi-mode \
  web-search yarn z \
)
autoload zmv
export PATH="\
/usr/local/opt/ruby/bin:\
/usr/local/bin:\
/usr/local/sbin:\
/opt/local/bin/:\
/opt/homebrew/bin:\
/usr/bin:\
/usr/sbin:\
/bin:\
/sbin:\
/usr/local/go/bin:\
$HOME/.cargo/bin:\
$HOME/src/toolbox/app:\
$HOME/bin:\
/usr/local/opt/python@3.9/Frameworks/Python.framework/Versions/3.9/bin:\
$(python -m site --user-base)/bin"
. "$ZSH/oh-my-zsh.sh"
. "$HOME/dotfiles/app/z.sh"
. "$HOME/dotfiles/aliases"
. "$HOME/dotfiles/functions"
case $(uname -a) in
  *Microsoft*)
    unsetopt BG_NICE
    MC=/usr/lib/mc/mc-wrapper.sh
    ;;
  *)
    case "$OSTYPE" in
      darwin*)
        MC=/usr/local/Cellar/midnight-commander/4.8.22/libexec/mc/mc-wrapper.sh
        export DISPLAY=:0
        export LC_ALL=en_US.UTF-8
        export LANG=en_US.UTF-8
        export PATH="$PATH":/Library/TeX/texbin
        if [ -d /usr/local/opt/fzf/shell ]; then
          export FZF_PATH=/usr/local/opt/fzf/shell
          PATH="$PATH":/usr/local/opt/fzf/bin
        elif [ -d /opt/homebrew/Cellar/fzf/0.30.0/shell ]; then
          export FZF_PATH=/opt/homebrew/Cellar/fzf/0.30.0/shell
          PATH="$PATH":/opt/homebrew/Cellar/fzf/0.30.0/bin
        else
          printf >&2 'Unable to find FZF_PATH.\n'
        fi
        ;;
      linux*)
        MC=/usr/lib/mc/mc-wrapper.sh
        export DISPLAY=:0
        export LC_ALL=en_US.UTF-8
        export LANG=en_US.UTF-8
        export PATH="/home/linuxbrew/.linuxbrew/bin:$PATH"
        export MANPATH="/home/linuxbrew/.linuxbrew/share/man:$MANPATH"
        export INFOPATH="/home/linuxbrew/.linuxbrew/share/info:$INFOPATH"
        if [ -f /etc/redhat-release ]; then
          export FZF_PATH=/usr/share/fzf/shell
          PATH="$PATH":/usr/share/fzf/bin
        elif [ -f /etc/arch-release ]; then
          export FZF_PATH=/usr/share/fzf
          PATH="$PATH":/usr/share/fzf/bin
        else
          export FZF_PATH=/usr/share/doc/fzf/examples
          PATH="$PATH":/usr/share/doc/fzf/bin
        fi
        ;;
      freebsd*)
        MC=/usr/local/libexec/mc/mc-wrapper.sh
        export FZF_PATH=/usr/local/share/examples/fzf/shell
        PATH="$PATH":/usr/local/share/examples/fzf/bin
        ;;
      openbsd*)
        MC=/usr/local/libexec/mc/mc-wrapper.sh
        export DISPLAY=:0
        export LC_ALL=en_US.UTF-8
        export LANG=en_US.UTF-8
        alias ls='gls --color'
        export FZF_PATH=/usr/local/share/examples/fzf/shell
        PATH="$PATH":/usr/local/share/examples/fzf/bin
        ;;
      msys*)
        MC=/usr/lib/mc/mc-wrapper.sh
        ;;
      *)
        printf 'Unknown OS: %s.\n' "$OSTYPE"
        ;;
    esac
esac

# Changes last directory of mc into shell.
alias mc=". $MC"
export DISABLE_AUTO_TITLE='true'

# Switches on vi command-line editing.
bindkey -v

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

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
if command -v rbenv >/dev/null 2>&1; then
  eval "$(rbenv init - zsh)"
fi
