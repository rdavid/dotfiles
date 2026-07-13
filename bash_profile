#!/bin/bash
# vi: lbr noet sw=2 ts=2 tw=79 wrap
# SPDX-FileCopyrightText: 2016-2026 David Rabkin
# SPDX-License-Identifier: 0BSD
#
# Configures Bash login sessions by loading the interactive settings and
# extending the search path.
#
# File is not following:
#  shellcheck disable=SC1090
[ -f ~/.bashrc ] && . ~/.bashrc
case :$PATH: in
*:"$HOME"/.cargo/bin:*) ;;
*)
	export PATH="$HOME/.cargo/bin:$PATH"
	;;
esac
