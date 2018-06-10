# zshrc
# vim: tabstop=2 shiftwidth=2 expandtab textwidth=80 linebreak wrap

# Cool man pager, viewer and editor.
export PAGER=most
export VISUAL=vim
export EDITOR=vim

# Path to your oh-my-zsh installation.
export ZSH=~/.oh-my-zsh

ZSH_THEME="wezm"

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
plugins=(archlinux battery brew catimg common-aliases compleat debian docker \
         docker-compose gem git git-extras git-flow github history lol osx \
         pip python ruby sudo terminator tmux vi-mode web-search yarn z)

# User configuration.
export PATH="/opt/local/bin/:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/home/linuxbrew/.linuxbrew/bin"

export PATH="/home/linuxbrew/.linuxbrew/bin:$PATH"
export MANPATH="/home/linuxbrew/.linuxbrew/share/man:$MANPATH"
export INFOPATH="/home/linuxbrew/.linuxbrew/share/info:$INFOPATH"

# Corrects work of tmuxp.
export PATH="`python -m site --user-base`/bin":$PATH

# Corrects work of fortune at Win10 Ubuntu.
export PATH="/usr/games":$PATH

. ~/dotfiles/app/z.sh

source $ZSH/oh-my-zsh.sh

alias src="source ~/.zshrc"
alias src-tmux="tmux source-file ~/.tmux.conf"
alias vi="vim"
alias h="history"
alias vpn="sudo openvpn --config ~/app/dat/David_Rabkin@vpn.safe-t.com.ovpn"

#Starts X.
if [[ ! $DISPLAY && $XDG_VTNR -eq 1 ]]; then
  exec startx
fi

# Starts tmux.
if [[ "$TERM" != "screen" ]] && 
   [[ -z "$TMUX" ]] &&
   ! test tmux has-session -t main 2>/dev/null; then

  tmuxp load ~/dotfiles/tmux/plugins/tmuxp/main.yaml
else
  # One might want to do other things in this case, 
  # here I print my motd, but only on servers where 
  # one exists.

  # If inside tmux session then print MOTD.
  MOTD=/etc/motd.tcl
  if [ -f $MOTD ]; then
    $MOTD
  fi
fi

# fh - repeat history
fh() {
  print -z $( ([ -n "$ZSH_NAME" ] && fc -l 1 || history) | fzf +s --tac | sed 's/ *[0-9]* *//')
}
