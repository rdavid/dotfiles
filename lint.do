# shellcheck shell=sh
# vi: lbr noet sw=2 ts=2 tw=79 wrap
# SPDX-FileCopyrightText: 2024-2026 David Rabkin
# SPDX-License-Identifier: 0BSD
redo-ifchange \
	./.github/*.yml \
	./.github/workflows/*.yml \
	./*.do \
	./.rubocop.yml \
	./aliases \
	./app/lock \
	./app/merge_history.sh \
	./bash_profile \
	./bashrc \
	./functions \
	./install \
	./install.rb \
	./README.adoc \
	./xinitrc \
	./zshrc

# shellcheck disable=SC2034 # Variable appears unused.
readonly \
	BASE_APP_VERSION=0.9.20260712 \
	BSH=/usr/local/bin/base.sh
[ -r "$BSH" ] || {
	printf >&2 Install\ Shellbase.\\n
	exit 1
}
set -- "$@" --quiet

# shellcheck disable=SC1090 # File not following.
. "$BSH"
cmd_exists actionlint && actionlint
cmd_exists rubocop && rubocop
cmd_exists ruff && ruff check ./app ./i3
cmd_exists shellcheck &&
	shellcheck \
		./*.do \
		./aliases \
		./app/lock \
		./app/merge_history.sh \
		./bash_profile \
		./bashrc \
		./functions \
		./install \
		./xinitrc \
		./zshrc
cmd_exists shfmt &&
	shfmt -d \
		./*.do \
		./aliases \
		./app/lock \
		./app/merge_history.sh \
		./bash_profile \
		./bashrc \
		./functions \
		./install \
		./xinitrc \
		./zshrc
cmd_exists typos && typos
cmd_exists vale && {
	vale sync
	vale ./README.adoc
}
cmd_exists yamllint &&
	yamllint \
		./.github/*.yml \
		./.github/workflows/*.yml \
		./.rubocop.yml

# Keeps the script from failing when the last tool is missing.
:
