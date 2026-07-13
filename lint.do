# shellcheck shell=sh
# vi: lbr noet sw=2 ts=2 tw=79 wrap
# SPDX-FileCopyrightText: 2024-2026 David Rabkin
# SPDX-License-Identifier: 0BSD
#
# Lints the repository with whichever linters are installed, skipping the
# missing ones. Command output streams to the console through the shellbase
# loggers, while the script itself prints only OK to stdout, which redo
# captures as the target. Dash and mksh check syntax one file per
# invocation: a POSIX shell reads only its first operand as the script and
# hands any further operands to it as positional parameters, so files after
# the first would be silently skipped rather than checked. The zshrc file
# stays out of the syntax loop because it uses zsh-only constructs.
#
# Variable appears unused and file not following:
#  shellcheck disable=SC2034,SC1090
redo-ifchange \
	./.github/*.yml \
	./.github/workflows/*.yml \
	./.rubocop.yml \
	./*.do \
	./aliases \
	./app/* \
	./bash_profile \
	./bashrc \
	./functions \
	./i3/*.py \
	./install \
	./install.rb \
	./README.adoc \
	./REUSE.toml \
	./xinitrc \
	./zshrc
BSH=/usr/local/bin/base.sh
[ -r "$BSH" ] || {
	printf >&2 'Install Shellbase.\n'
	exit 1
}
readonly \
	BASE_APP_VERSION=0.9.20260713 \
	BASE_MIN_VERSION=0.9.20260707 \
	BSH
. "$BSH"
cmd_runif actionlint
for f in \
	./*.do \
	./aliases \
	./app/lock \
	./app/merge_history.sh \
	./bash_profile \
	./bashrc \
	./functions \
	./install \
	./xinitrc; do
	cmd_runif dash -n "$f"
	cmd_runif mksh -n "$f"
done
cmd_runif reuse lint
cmd_runif rubocop
cmd_runif ruff check ./app ./i3
cmd_runif shellcheck \
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
cmd_runif shfmt -d \
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
cmd_runif typos
cmd_runif vale sync
cmd_runif vale ./README.adoc
cmd_runif yamllint \
	./.github/*.yml \
	./.github/workflows/*.yml \
	./.rubocop.yml
cmd_runif zizmor --offline ./.github/
printf OK
