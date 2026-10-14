# shellcheck shell=sh
# vi: lbr noet sw=2 ts=2 tw=79 wrap
# SPDX-FileCopyrightText: 2026 David Rabkin
# SPDX-License-Identifier: 0BSD
#
# Loads fzf completion and key bindings into Bash. Replaces the stub that the
# fzf installer generates, which pins a single Homebrew prefix, with a version
# that detects the installation. Uses the first known prefix that exists.
#
# The sourced files are not followed:
#  shellcheck disable=SC1091
for dir in \
	/opt/homebrew/opt/fzf \
	/usr/local/opt/fzf \
	/home/linuxbrew/.linuxbrew/opt/fzf; do
	[ -d "$dir" ] || continue

	# Adds the fzf binaries to the path unless they are already there.
	case :$PATH: in
	*:"$dir"/bin:*) ;;
	*)
		export PATH="$PATH:$dir/bin"
		;;
	esac

	# Loads the completion in interactive shells only.
	case $- in
	*i*)
		. "$dir"/shell/completion.bash 2>/dev/null
		;;
	esac

	# Loads the key bindings and stops at the first prefix found.
	. "$dir"/shell/key-bindings.bash
	break
done
