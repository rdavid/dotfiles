#!/usr/bin/env bash
# vim: tabstop=2 shiftwidth=2 expandtab textwidth=80 linebreak wrap
#
# make.sh
#
# Copyright 2017 David Rabkin
#
# This script creates symlinks from the home directory to any desired
# dotfiles in ~/dotfiles. Also it installs needfull modules.

dir=~/dotfiles                    # dotfiles directory
olddir=~/dotfiles_old             # old dotfiles backup directory

# List of files/folders to symlink in homedir.
files="bashrc bash_profile vimrc vim zshrc oh-my-zsh tmux.conf tmux"

# Creates dotfiles_old in homedir.
echo -n "Creating $olddir for backup of any existing dotfiles in ~ ..."
mkdir -p $olddir
echo "done."

# Changes to the dotfiles directory.
echo -n "Changing to the $dir directory ..."
cd $dir
echo "done."

# Moves any existing dotfiles in homedir to dotfiles_old directory,
# then creates symlinks from the homedir to any files in the ~/dotfiles
# directory specified in $files.
for file in $files; do
  echo "Moving any existing dotfiles from ~ to $olddir."
  mv ~/.$file ~/dotfiles_old/
  echo "Creating symlink to $file in home directory."
  ln -s $dir/$file ~/.$file
done

# Installs needfull software.
pkgs="zsh tmux most python cowsay htop fortune lolcat"
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

      if [[ $pkg == 'fortune' ]]; then
        sudo pacman -S fortune-mod
      else 
        sudo pacman -S $pkg
      fi

    elif [[ -f /etc/redhat-release ]]; then
      sudo yum install $pkg 
    elif [[ -f /etc/debian_version ]]; then
      sudo apt-get install $pkg 

      if [[ $pkg == 'python' ]]; then
        sudo apt-get install python-pip
      fi
    fi
  elif [[ $platform == 'Darwin' ]]; then
    su admin -c "brew install $pkg"

    if [[ $pkg == 'python' ]]; then
      su admin -c "sudo easy_install pip"
    fi
  elif [[ $platform == 'FreeBSD' ]]; then

    if [[ $pkg == 'lolcat' ]]; then
      sudo pkg install rubygem-lolcat
    else 
      sudo pkg install $pkg

      if [[ $pkg == 'python' ]]; then
        sudo pkg install py27-pip
      fi
    fi
  fi
done

# Sets the default shell to zsh if it isn't currently set to zsh.
if [[ ! $(echo $SHELL) == $(which zsh) ]]; then
  chsh -s $(which zsh)
fi

# Clones my oh-my-zsh repository from GitHub.
if [[ ! -d $dir/oh-my-zsh/ ]]; then
  git clone https://github.com/robbyrussell/oh-my-zsh.git
fi

if [[ ! -d $dir/tmux/plugins/tpm ]]; then
  git clone https://github.com/tmux-plugins/tpm ~/dotfiles/tmux/plugins/tpm
fi

# Installs tmux session manager.
if [[ $(python -c "help('modules');" | grep tmuxp | wc -l | xargs) == "0" ]]; then
  pip install --user tmuxp
fi
