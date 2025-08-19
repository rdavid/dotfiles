# shellcheck shell=sh
# vi:et lbr noet sw=2 ts=2 tw=79 wrap
# SPDX-FileCopyrightText: 2024-2025 David Rabkin
# SPDX-License-Identifier: 0BSD
redo-ifchange \
	./.github/*.yml \
	./.github/workflows/*.yml \
	./*.do \
	./install \
	./install.rb \
	./README.adoc

# shellcheck disable=SC2034 # Variable appears unused.
readonly \
	BASE_APP_VERSION=0.9.20250820 \
	BASE_MIN_VERSION=0.9.20231212 \
	BSH=/usr/local/bin/base.sh
[ -r "$BSH" ] || {
	printf >&2 Install\ Shellbase.\\n
	exit 1
}
set -- "$@" --quiet

# shellcheck disable=SC1090 # File not following.
. "$BSH"
cmd_exists rubocop && rubocop
cmd_exists shellcheck && shellcheck ./*.do ./install ./zshrc
cmd_exists shfmt && shfmt -d ./*.do ./install ./zshrc
cmd_exists typos && typos
cmd_exists vale && {
	vale sync
	vale ./README.adoc
}


 # Gracefully handle missing tool without failing the script.
 # shellcheck disable=SC2015 # A && B || C is not if-then-else.
cmd_exists yamllint && yamllint ./.github/*.yml ./.github/workflows/*.yml || :
