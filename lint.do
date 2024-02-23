# shellcheck shell=sh
# vi:et lbr noet sw=2 ts=2 tw=79 wrap
# Copyright 2024 David Rabkin
redo-ifchange \
	./*.do \
	./install \
	.github/*.yml \
	.github/workflows/*.yml \
	README.adoc

# shellcheck disable=SC2034 # Variable appears unused.
readonly \
	BASE_APP_VERSION=0.9.20240224 \
	BASE_MIN_VERSION=0.9.20231212 \
	BSH=/usr/local/bin/base.sh
[ -r "$BSH" ] || {
	printf >&2 Install\ Shellbase.\\n
	exit 1
}
set -- "$@" --quiet

# shellcheck disable=SC1090 # File not following.
. "$BSH"
cmd_exists shellcheck && shellcheck ./*.do install
cmd_exists shfmt && shfmt -d ./*.do install
cmd_exists typos && typos
cmd_exists vale && {
	vale sync
	vale README.adoc
}
cmd_exists yamllint && yamllint .github/*.yml .github/workflows/*.yml
