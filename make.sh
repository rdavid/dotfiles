#!/usr/bin/env bash
# vim: tabstop=2 shiftwidth=2 expandtab textwidth=80 linebreak wrap
#
# make.sh
#
# Copyright 2018 David Rabkin
#
# This script preparies ruby environment to run make.rb.
# Installs needfull software.

pkgs="ruby"
for pkg in $pkgs; do
  # Tests to see if a package is installed.
  if [[ -f "/bin/$pkg" ]]; then
    echo "/bin/$pkg is already installed."
    continue
  fi

  if [[ -f "/usr/bin/$pkg" ]]; then
    echo "/usr/bin/$pkg is already installed."
    continue
  fi

  if [[ -f "/usr/local/bin/$pkg" ]]; then
    echo "/usr/local/bin/$pkg is already installed."
    continue
  fi

  echo "$pkg is installed."

  platform=$(uname);
  if [[ $platform == 'Linux' ]]; then
    if [[ -f /etc/arch-release ]]; then
      sudo pacman --noconfirm -S $pkg
    elif [[ -f /etc/redhat-release ]]; then
      sudo yum install $pkg 
    elif [[ -f /etc/debian_version ]]; then
      sudo apt-get -y install $pkg 
    fi
  elif [[ $platform == 'Darwin' ]]; then
    brew cask install $pkg
  elif [[ $platform == 'FreeBSD' ]]; then
    sudo pkg install $pkg devel/ruby-gems
  fi
done

# Installs needful packages.
gems="colorize git os terminal-table"
for g in $gems; do
  if ! `gem list -i $g`; then
    platform=$(uname);
    if [[ $platform == 'Darwin' ]]; then
      sudo gem install $g
    else
      gem install $g
    fi
    echo "Gem $g is installed."
  else
    echo "Gem $g is already installed."
  fi
done

# Runs Ruby's make.
$(dirname "$0")/make.rb "$@"
