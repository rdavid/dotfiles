#!/bin/bash

# Launches zsh.
if [ -t 1 ]; then
  exec zsh
fi

PATH=/opt/local/bin:$PATH

# Easier navigation: .., ..., ...., ....., ~ and -
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."
alias ~="cd ~" # `cd` is probably faster to type though
alias -- -="cd -"
alias vi="vim"

# Detects which `ls` flavor is in use.
if ls --color > /dev/null 2>&1; then # GNU `ls`
  colorflag="--color"
else # OS X `ls`
  colorflag="-G"
fi

# Lists all files colorized in long format.
alias l="ls -lF ${colorflag}"

# Lists all files colorized in long format, including dot files.
alias ll="ls -laF ${colorflag}"

# Lists only directories.
alias lsd="ls -lF ${colorflag} | grep --color=never '^d'"

# Always uses color output for `ls`.
alias ls="command ls ${colorflag}"
export LS_COLORS='no=00:fi=00:di=01;34:ln=01;36:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:ex=01;32:*.tar=01;31:*.tgz=01;31:*.arj=01;31:*.taz=01;31:*.lzh=01;31:*.zip=01;31:*.z=01;31:*.Z=01;31:*.gz=01;31:*.bz2=01;31:*.deb=01;31:*.rpm=01;31:*.jar=01;31:*.jpg=01;35:*.jpeg=01;35:*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.mov=01;35:*.mpg=01;35:*.mpeg=01;35:*.avi=01;35:*.fli=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:*.ogg=01;35:*.mp3=01;35:*.wav=01;35:'

# Always enables colored `grep` output.
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias h='history'
alias untar='tar -zxvf'
alias speed='speedtest-cli --server 2406 --simple'
alias ipe='curl ipinfo.io/ip'
alias ipi='ipconfig getifaddr en0'
alias c='clear'

# Make vim the default editor.
export EDITOR='vim';

# Increases Bash history size. Allow 32³ entries; the default is 500.
export HISTSIZE='32768';
export HISTFILESIZE="${HISTSIZE}";

# Omits duplicates and commands that begin with a space from history.
export HISTCONTROL='ignoreboth';

# Highlights section titles in manual pages.
export LESS_TERMCAP_md="${yellow}";

# Doesn’t clear the screen after quitting a manual page.
export MANPAGER='less -X';

# Simple calculator.
function calc() {
  local result="";
  result="$(printf "scale=10;$*\n" | bc --mathlib | tr -d '\\\n')";
  if [[ "$result" == *.* ]]; then
    printf "$result" |
    sed -e 's/^\./0./'        `# add "0" for cases like ".5"` \
        -e 's/^-\./-0./'      `# add "0" for cases like "-.5"`\
        -e 's/0*$//;s/\.$//';  # remove trailing zeros
  else
    printf "$result";
  fi;

  printf "\n";
}

# Creates a new directory and enter it.
function mkd() {
  mkdir -p "$@" && cd "$_";
}

# Determines size of a file or total size of a directory.
function fs() {
  if du -b /dev/null > /dev/null 2>&1; then
    local arg=-sbh;
  else
    local arg=-sh;
  fi
  if [[ -n "$@" ]]; then
    du $arg -- "$@";
  else
    du $arg .[^.]* ./*;
  fi;
}
