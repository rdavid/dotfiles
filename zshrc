# shellcheck shell=sh
# vi:et lbr noet sw=2 ts=2 tw=79 wrap
# Copyright 2016-2024 David Rabkin

# Cool man pager, viewer and editor.
export \
	BAT_PAGER=less \
	BAT_THEME=zenburn \
	EDITOR=vim \
	HIST_STAMPS=%Y%m%d-%H:%M:%S \
	HISTCONTROL=ignoredups \
	HISTIGNORE=install:youtube-dl \
	PAGER=most \
	VISUAL=vim

# Path to your oh-my-zsh installation.
export \
	ZSH="$HOME"/.oh-my-zsh \
	ZSH_THEME=minimal

# Uncomment the following line to change how often to auto-update (in days).
export UPDATE_ZSH_DAYS=30

# Uncomment the following line to display red dots whilst waiting for
# completion.
export COMPLETION_WAITING_DOTS=true
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
# shellcheck disable=SC3030 # Arrays are undefined.
export plugins=(
	archlinux battery brew catimg colored-man-pages colorize common-aliases
	compleat debian docker docker-compose gem git git-extras git-flow github
	golang history macos pip python rsync ruby sudo tmux vi-mode
	web-search yarn z
)
autoload zmv

# Ensure that the GNUbin directory takes precedence over /usr/bin.
PATH="\
$HOME/.cargo/bin:\
$HOME/.local/bin:\
$HOME/bin:\
$HOME/Library/Python/3.9/bin:\
$HOME/src/toolbox/app:\
/usr/local/opt/grep/libexec/gnubin:\
/usr/local/opt/ruby/bin:\
/usr/local/lib/ruby/gems/3.2.0/bin:\
/usr/local/bin:\
/usr/local/sbin:\
/usr/local/go/bin:\
/opt/homebrew/bin:\
/opt/homebrew/opt/grep/libexec/gnubin:\
/opt/local/bin/:\
/usr/sbin:\
/usr/bin:\
/sbin:\
/bin:\
"
command -v go >/dev/null 2>&1 && PATH=$PATH:$(go env GOPATH)/bin
export PATH

# shellcheck disable=SC1090 # File not following.
for f in \
	"$ZSH"/oh-my-zsh.sh \
	"$HOME"/dotfiles/app/z.sh \
	"$HOME"/dotfiles/aliases \
	"$HOME"/dotfiles/functions; do
	. "$f"
done
case $(uname -a) in
*Microsoft*)
	unsetopt BG_NICE
	;;
*)
	# shellcheck disable=SC3028 # OSTYPE is undefined.
	case "$OSTYPE" in
	darwin*)
		export DISPLAY=:0 \
			LANG=en_US.UTF-8 \
			LC_ALL=en_US.UTF-8 \
			PATH="$PATH":/Library/TeX/texbin
		if [ -d /usr/local/opt/fzf/shell ]; then
			export FZF_PATH=/usr/local/opt/fzf/shell
			PATH="$PATH":/usr/local/opt/fzf/bin
		elif [ -d /opt/homebrew/Cellar/fzf/0.46.1/shell ]; then
			export FZF_PATH=/opt/homebrew/Cellar/fzf/0.46.1/shell
			PATH="$PATH":/opt/homebrew/Cellar/fzf/0.46.1/bin
		else
			printf >&2 'Unable to find FZF_PATH for Darwin.\n'
		fi
		;;
	linux*)
		export DISPLAY=:0 \
			INFOPATH=/home/linuxbrew/.linuxbrew/share/info:"$INFOPATH" \
			LANG=en_US.UTF-8 \
			LC_ALL=en_US.UTF-8 \
			MANPATH=/home/linuxbrew/.linuxbrew/share/man:"$MANPATH" \
			PATH=/home/linuxbrew/.linuxbrew/bin:"$PATH"
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
		export FZF_PATH=/usr/local/share/examples/fzf/shell
		PATH="$PATH":/usr/local/share/examples/fzf/bin
		;;
	openbsd*)
		export DISPLAY=:0 \
			FZF_PATH=/usr/local/share/examples/fzf/shell \
			LANG=en_US.UTF-8 \
			LC_ALL=en_US.UTF-8 \
			alias ls='gls --color'
		PATH="$PATH":/usr/local/share/examples/fzf/bin
		;;
	msys*) ;;
	*)
		printf >&2 'Unknown OS: %s.\n' "$OSTYPE"
		;;
	esac
	;;
esac

# Switches on vi command-line editing.
bindkey -v

# Starts X if installed.
[ -z "$DISPLAY" ] &&
	[ "$XDG_VTNR" -eq 1 ] &&
	command -v startx >/dev/null 2>&1 &&
	exec startx

# Starts tmux. If inside tmux session then print MOTD.
if [ "$TERM" != screen ] &&
	[ -z "$TMUX" ] &&
	! test tmux has-session -t main 2>/dev/null; then
	tmuxp load ~/dotfiles/tmux/plugins/tmuxp/main.yaml
else
	MOTD=/etc/motd.tcl
	if [ -f $MOTD ]; then
		$MOTD
	fi
fi

# shellcheck disable=SC1090 # File not following.
[ -f ~/.fzf.zsh ] && . ~/.fzf.zsh
command -v rbenv >/dev/null 2>&1 && eval "$(rbenv init - zsh)"
command -v thefuck >/dev/null 2>&1 && eval "$(thefuck --alias)"
