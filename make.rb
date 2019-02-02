#!/usr/bin/env ruby
# vim: tabstop=2 shiftwidth=2 expandtab textwidth=80 linebreak wrap
#
# make.rb
#
# Copyright 2017-2018 David Rabkin
#
# This script creates symlinks from the home directory to any desired
# dotfiles in ~/dotfiles. Also it installs needfull packages.
#
# For MacOS run without X and with the password for binary:
#   make --no-xorg -pass pass
#

require 'os'
require 'git'
require 'optparse'
require 'fileutils'
require 'English'

# Handles input parameters.
class Configuration
  DIC = [
    ['-g', '--[no-]xorg', 'Install X packagest.', :xorg],
    ['-p', '--pass pass', 'Password for binary.', :pass]
  ].freeze

  def initialize
    ARGV << '-h' if ARGV.empty?
    @options = {}
    OptionParser.new do |o|
      o.banner = 'Usage: make.rb [options].'
      DIC.each { |f, p, d, k| o.on(f, p, d) { |i| @options[k] = i } }
    end.parse!
    raise 'Xorg option is not given' if xorg?.nil?
    raise 'Pass option is not given' if xorg? && pass.nil?
  end

  def xorg?
    @options[:xorg]
  end

  def pass
    @options[:pass]
  end
end

# Base class for definition of multiple OS.
class OS
  attr_reader :type
  attr_reader :test
  attr_reader :inst
  attr_reader :prec
  attr_reader :post
  attr_reader :pkgs
  attr_reader :dotf
  attr_reader :conf

  def initialize(cfg)
    @type = ''
    @test = ''
    @inst = ''
    @post = ''
    @prec = ''

    # Packages without Xorg to install.
    @pkgs = %w[
      atop bat cmatrix cmus cowsay curl f3 ffmpeg figlet fortune handbrake htop
      imagemagick mc most ncdu npm nnn python scrot tmux vim wget zsh
      zsh-syntax-highlighting
    ]

    # List of files/folders to symlink in homedir.
    @dotf = %w[bash_profile bashrc oh-my-zsh tmux.conf tmux vim vimrc zshrc]

    # List of files/folders to symlink in ~/.config.
    @conf = %w[mc]

    # For MacOS run '--no-xorg --pass'.
    unless cfg.pass.nil?
      @prec << %{
        rm -rf ~/dotfiles/bin
        unzip -P #{cfg.pass} ~/dotfiles/bin.zip -d ~/dotfiles
      }
    end
    xconfigure if cfg.xorg?
  end

  def xconfigure
    @prec << %{
      mkdir -p ~/.fonts
      for f in inconsolata-g.otf pragmatapro.ttf; do
        if [[ ! -e ~/.fonts/$f ]]; then
          ln -s ~/dotfiles/bin/$f ~/.fonts
        fi
      done
      fc-cache -vf
    }
    # Extends with Xorg related packages.
    (@pkgs << %w[
      conky dropbox feh firefox font-awesome google-chrome i3 i3blocks i3lock
      keepassxc kitty okular sublime-text terminator visual-studio-code
    ]).flatten!
    (@dotf << %w[i3 xinitrc]).flatten!
    (@conf << %w[conky kitty terminator]).flatten!
  end

  private :xconfigure
end

# Implements MacOS.
module MacOS
  def self.extended(mod)
    mod.type << 'MacOS'
    mod.prec << %{
      for f in inconsolata-g.otf pragmatapro.ttf; do
        if [[ ! -e ~/Library/Fonts/$f ]]; then
          cp ~/dotfiles/bin/$f ~/Library/Fonts/
        fi
      done
      sudo easy_install pip
      export HOMEBREW_CASK_OPTS="--appdir=/Applications"
      if hash brew &> /dev/null; then
        echo "Homebrew already installed."
      else
        ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
      fi
      brew cask upgrade
      brew cleanup && brew cask cleanup
    }
    (
      # feh has to be after xquartz.
      mod.pkgs << %w[
        docker dropbox firefox fonts-font-awesome google-chrome iterm2 keepassxc
        keepingyouawake lolcat nmap pry sublime-text telegram tunnelblick
        virtualbox visual-studio-code vox xquartz feh
      ]
    ).flatten!
    mod.test << 'brew ls --versions %s >/dev/null 2>&1'
    mod.inst << 'brew install %s || brew cask install %s'
  end
end

# Implements FreeBSD.
module FreeBSD
  DIC = {
    fortune: 'fortune-mod-freebsd-classic'
  }

  def self.extended(mod)
    mod.type << 'FreeBSD'
    (
      mod.pkgs << %w[
        py27-pip rubygem-pry-rails rubygem-lolcat
      ]
    ).flatten!.map! { |i| DIC[i.to_sym].nil? ? i : DIC[i.to_sym] }
    mod.test << 'pkg info %s >/dev/null 2>&1'
    mod.inst << 'sudo pkg install -y %s'
  end
end

# Implements OpenBSD.
module OpenBSD
  DIC = {
    fortune: 'fortune-mod-freebsd-classic'
  }

  def self.extended(mod)
    mod.type << 'OpenBSD'
    (
      mod.pkgs << %w[
        py27-pip rubygem-pry-rails rubygem-lolcat
      ]
    ).flatten!.map! { |i| DIC[i.to_sym].nil? ? i : DIC[i.to_sym] }
    mod.test << 'pkg_info %s >/dev/null 2>&1'
    mod.inst << 'doas pkg_add %s'
  end
end

# Implements Arch Linux.
module Arch
  DIC = {
    fortune:        'fortune-mod',
    'font-awesome': 'ttf-font-awesome'
  }

  def self.extended(mod)
    mod.type << 'Arch'
    mod.prec << %{
      if [[ ! `cat /etc/pacman.conf | grep archlinuxfr` ]]; then
        echo "
          [archlinuxfr]
          SigLevel = Never
          Server = http://repo.archlinux.fr/$arch
        " | sudo tee -a /etc/pacman.conf
        sudo pacman -Sy yaourt --noconfirm
      fi
      yaourt -Syauu --noconfirm
    }
    (
      mod.pkgs << %w[
        alsa-utils fzf handbrake-cli lolcat python-pip ruby-pry
      ]
    ).flatten!.map! { |i| DIC[i.to_sym].nil? ? i : DIC[i.to_sym] }
    mod.test << 'yaourt -Qs --nameonly %s >/dev/null 2>&1'
    mod.inst << 'yaourt -Sy --noconfirm %s'
    mod.post << %{
      #sed -i 's/usr\/share/usr\/lib/g' ~/.i3/i3blocks.conf
    }
  end
end

# Implements Debian Linux.
module Debian
  DIC = {
    'font-awesome': 'fonts-font-awesome'
  }

  def self.extended(mod)
    mod.type << 'Debian'
    mod.prec << %{
      sudo apt-get -y update
      sudo apt-get -y dist-upgrade
      curl -sL https://deb.nodesource.com/setup_9.x | sudo -E bash -
    }
    (
      mod.pkgs << %w[
        apcalc byobu lolcat pry python-pip
      ]
    ).flatten!.map! { |i| DIC[i.to_sym].nil? ? i : DIC[i.to_sym] }
    mod.test << 'dpkg -l %s >/dev/null 2>&1'
    mod.inst << 'sudo apt-get -y install %s'
  end
end

# Implements RedHat Linux.
module RedHat
  DIC = {
    'font-awesome': 'fontawesome-fonts'
  }

  def self.extended(mod)
    mod.type << 'RedHat'
    (
      mod.pkgs << %w[
        lolcat pry
      ]
    ).flatten!.map! { |i| DIC[i.to_sym].nil? ? i : DIC[i.to_sym] }
    mod.test << 'yum list installed %s >/dev/null 2>&1'
    mod.inst << 'sudo yum -y install %s'
  end
end

# Implements Alpine Linux.
module Alpine
  def self.extended(mod)
    mod.type << 'Alpine'
    (
      mod.pkgs << %w[
        lolcat py-pip pry
      ]
    ).flatten!
    mod.test << 'apk info %s >/dev/null 2>&1'
    mod.inst << 'sudo apk add %s'
  end
end

# Defines current OS.
class CurrentOS
  def self.get
    return MacOS   if OS.mac?
    return FreeBSD if OS.freebsd?
    return OpenBSD if OS.host_os=~/openbsd/
    return Arch    if OS.linux? && File.file?('/etc/arch-release')
    return Debian  if OS.linux? && File.file?('/etc/debian_version')
    return RedHat  if OS.linux? && File.file?('/etc/redhat-release')
    return Alpine  if OS.linux? && File.file?('/etc/alpine-release')

    raise 'Current OS is not supported.'
  end
end

# Actually does the job.
class Installer
  def initialize
    @os = OS.new(Configuration.new).extend(CurrentOS.get)
    @ndir = File.join(Dir.home, 'dotfiles')
    @odir = File.join(Dir.home, 'dotfiles-old')
  end

  def do
    @os.pkgs.sort!
    puts("Hello #{@os.type}: #{@os.pkgs}: #{@os.dotf}: #{@os.conf}.")

    # Runs pre-install commands.
    system('bash', '-c', @os.prec) unless @os.prec.empty?

    # Install packages.
    @os.pkgs.each do |p|
      # Tests if a package is installed.
      system(@os.test % p)

      # Installs new packages.
      if $CHILD_STATUS.exitstatus > 0
        puts("Install: #{p}.")
        system(@os.inst.gsub('%s', p))
      else
        puts("#{p} is already installed.")
      end
    end

    # Creates directory for existing dot files.
    FileUtils.mkdir_p(@odir)

    # Moves any existing dotfiles in homedir to dotfiles_old directory,
    # then creates symlinks from the homedir to any files in the ~/dotfiles
    # directory specified in $files.
    @os.dotf.each do |f|
      src = File.join(Dir.home, '.' + f)
      dst = File.join(@odir, '.' + f)
      if File.exist?(src) && !File.symlink?(src)
        puts("mv #{src}->#{dst}.")
        FileUtils.mv(src, dst)
      end
      FileUtils.ln_s(File.join(@ndir, f), src, force: true)
    end

    # Prevents mc link error.
    FileUtils.mkdir_p(File.join(Dir.home, '.config'))

    # Handles ~/.config in similar way.
    FileUtils.mkdir_p(File.join(@odir, '.config'))
    @os.conf.each do |f|
      src = File.join(Dir.home, '.config', f)
      dst = File.join(@odir, '.config', f)
      if File.exist?(src) && !File.symlink?(src)
        puts("mv #{src}->#{dst}.")
        FileUtils.mv(src, dst)
      end
      FileUtils.ln_s(File.join(@ndir, f), src, force: true)
    end
    system('bash', '-c', @os.post) unless @os.post.empty?

    # Sets the default shell to zsh if it isn't currently set to zsh.
    sh = ENV['SHELL']
    unless sh.eql? `which zsh`.strip
      system('bash', '-c', 'chsh -s $(which zsh)')
      puts("Unable to switch #{sh} to zsh.") unless $CHILD_STATUS.exitstatus > 0
    end

    # Clones repositories out from GitHub.
    [
      {
        src: 'https://github.com/robbyrussell/oh-my-zsh',
        dst: File.join(@ndir, 'oh-my-zsh')
      },
      {
        src: 'https://github.com/tmux-plugins/tpm',
        dst: File.join(@ndir, 'tmux', 'plugins', 'tpm')
      }
    ].each do |i|
      Git.clone(i[:src], i[:dst]) unless Dir.exist?(i[:dst])
    end

    # Installs Python packages.
    %w[
      glances s_tui speedtest-cli tmuxp youtube_dl
    ].each do |p|
      chk = "python -c \"help('modules');\" | grep #{p} | wc -l | xargs"
      next if `#{chk}`.strip.eql? '1'

      system("pip install --user #{p}")
      puts("Unable to install #{p}.") unless $CHILD_STATUS.exitstatus > 0
    end

    # Installs Ruby packages.
    %w[
      video_transcoding terminal-table
    ].each do |p|
      chk = "gem list -i #{p}"
      next if `#{chk}`.strip.eql? 'true'

      system("gem install #{p}")
      puts("Unable to install #{p}.") unless $CHILD_STATUS.exitstatus > 0
    end

    # Installs NoJS packages.
    %w[
      gtop
    ].each do |p|
      system("npm list -g #{p}")
      next unless $CHILD_STATUS.exitstatus

      system("npm install #{p}")
      puts("Unable to install #{p}.") unless $CHILD_STATUS.exitstatus > 0
    end
    puts('Bye-bye.')
  end
end

Installer.new.do
