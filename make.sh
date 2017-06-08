 #!/usr/bin/env bash
 # vim: tabstop=2 shiftwidth=2 expandtab textwidth=80 linebreak wrap
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
pkgs="zsh tmux"
for pkg in $pkgs; do

  # Tests to see if a package is installed.
  if [[ ! -f "/bin/$pkg" ]]; then
    echo "$pkg is installed."
    continue
  fi

  if [[ ! -f "/usr/local/bin/$pkg" ]]; then
    echo "$pkg is installed."
    continue
  fi
  
  echo "Install $pkg."

  platform=$(uname);
  if [[ $platform == 'Linux' ]]; then
    if [[ -f /etc/arch-release ]]; then
      sudo pacman -S $pkg
    elif [[ -f /etc/redhat-release ]]; then
      sudo yum install $pkg 
    elif [[ -f /etc/debian_version ]]; then
      sudo apt-get install $pkg 
    fi
  elif [[ $platform == 'Darwin' ]]; then
    su admin -c brew install $pkg
  elif [[ $platform == 'FreeBSD' ]]; then
    sudo pkg install $pkg
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

if [[ ! -d $dir/tmux/ ]]; then
  git clone https://github.com/tmux-plugins/tpm ~/dotfiles/tmux/plugins/tpm
fi
