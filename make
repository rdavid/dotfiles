#!/bin/sh
# vi:et lbr noet sw=2 ts=2 tw=79 wrap
# Copyright 2018-2022 David Rabkin
#
# This script preparies ruby environment to run make.rb.
# Installs needfull software.

# shellcheck disable=SC1091
. base.sh
platform="$(uname)"
readonly \
	gems='colorize english git i18n os pidfile' \
	platform \
	pkgs=ruby

# Tests to see if a package is installed.
for p in $pkgs; do
	cmd_exists "$p" || {
		if [ "$platform" = Linux ]; then
			if [ -f /etc/arch-release ]; then
				sudo pacman --noconfirm -S "$p"
			elif [ -f /etc/redhat-release ]; then
				sudo dnf install --assumeyes "$p"
			elif [ -f /etc/debian_version ]; then
				sudo apt-get install --assume-yes "$p"
			fi
		elif [ "$platform" = Darwin ]; then
			brew install "$p"
		elif [ "$platform" = FreeBSD ]; then
			sudo pkg install "$p" devel/ruby-gems
		fi
		log "$p" is installed.
	}
done

# Installs needful Ruby packages.
for g in $gems; do
	gem list -ie "$g" >/dev/null 2>&1 || {
		if [ -f /etc/arch-release ]; then
			gem install "$g"
		else
			sudo gem install "$g"
		fi
		log "$g" is installed.
	}
done

# Runs Ruby's make.
"$(dirname "$0")"/make.rb "$@"
