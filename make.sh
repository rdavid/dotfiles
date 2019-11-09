#!/bin/sh
# vim: tabstop=2 shiftwidth=2 expandtab textwidth=80 linebreak wrap
#
# Copyright 2018-present David Rabkin
#
# This script preparies ruby environment to run make.rb.
# Installs needfull software.

platform=$(uname);
pkgs='ruby'
for p in $pkgs; do
  # Tests to see if a package is installed.
  if command -v "$p" >/dev/null 2>&1; then
    echo "$p is already installed."
    continue
  fi
  if [ "$platform" = 'Linux' ]; then
    if [ -f /etc/arch-release ]; then
      sudo pacman --noconfirm -S "$p"
    elif [ -f /etc/redhat-release ]; then
      sudo yum install "$p"
    elif [ -f /etc/debian_version ]; then
      sudo apt-get -y install "$p"
    fi
  elif [ "$platform" = 'Darwin' ]; then
    brew cask install "$p"
  elif [ "$platform" = 'FreeBSD' ]; then
    sudo pkg install "$p" devel/ruby-gems
  fi
  echo "$p is installed."
done

# Installs needful packages.
gems='colorize git i18n os'
for g in $gems; do
  if gem list -i "$g" >/dev/null 2>&1; then
    echo "$g is already installed."
    continue
  fi
  if [ -f /etc/arch-release ]; then
    gem install "$g"
  else
    sudo gem install "$g"
  fi
  echo "$g is installed."
done

# Runs Ruby's make.
"$(dirname "$0")/make.rb" "$@"
