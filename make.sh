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
files="bashrc bash_profile vimrc vim zshrc oh-my-zsh tmux.conf tmux xinitrc i3"

# Creates dotfiles_old in homedir.
mkdir -p $olddir

# Changes to the dotfiles directory.
cd $dir

# Moves any existing dotfiles in homedir to dotfiles_old directory,
# then creates symlinks from the homedir to any files in the ~/dotfiles
# directory specified in $files.
for file in $files; do

  if [ -e ~/.$file ]; then
    mv ~/.$file ~/dotfiles_old/
  fi

  ln -s $dir/$file ~/.$file
done

if [ -d ~/.config/conky ]; then
  mv ~/.config/conky ~/dotfiles_old/
fi

ln -s $dir/conky ~/.config/conky

# Installs needfull software.
pkgs="zsh tmux most python cowsay htop fortune lolcat feh conky scrot
imagemagick i3 i3lock cmatrix hollywood hddtemp glances htop"
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
      sudo apt-get -y install $pkg 

      if [[ $pkg == 'python' ]]; then
        sudo apt-get -y install python-pip
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

# Installs transcode-video.
if [[ $(gem list -i video_transcoding) == "false" ]]; then
  sudo gem install video_transcoding 
else
  sudo gem update video_transcoding
fi
