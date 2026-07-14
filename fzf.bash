# shellcheck shell=sh
# vi: lbr noet sw=2 ts=2 tw=79 wrap
# SPDX-FileCopyrightText: 2026 David Rabkin
# SPDX-License-Identifier: 0BSD
#
# Loads fzf completion and key bindings into Bash. Replaces the stub that
# the fzf installer generates, which pins a single Homebrew prefix, with
# one that detects the installation.
#
# Files are not following:
#  shellcheck disable=SC1091
for dir in \
	/opt/homebrew/opt/fzf \
	/usr/local/opt/fzf \
	/home/linuxbrew/.linuxbrew/opt/fzf; do
	[ -d "$dir" ] || continue
	case :$PATH: in
	*:"$dir"/bin:*) ;;
	*)
		export PATH="$PATH:$dir/bin"
		;;
	esac
	case $- in
	*i*)
		. "$dir"/shell/completion.bash 2>/dev/null
		;;
	esac
	. "$dir"/shell/key-bindings.bash
	break
done
