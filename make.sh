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
    echo "/bin/$pkg is installed."
    continue
  fi

  if [[ -f "/usr/bin/$pkg" ]]; then
    echo "/usr/bin/$pkg is installed."
    continue
  fi

  if [[ -f "/usr/local/bin/$pkg" ]]; then
    echo "/usr/local/bin/$pkg is installed."
    continue
  fi

  echo "Install $pkg."

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
    su admin -c "brew install $pkg"
  elif [[ $platform == 'FreeBSD' ]]; then
    sudo pkg install $pkg
  fi
done

# Installs needful packages.
gems = "os git"
for g in $gems; do
  gem install g
done
