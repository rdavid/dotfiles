#!/usr/bin/env ruby
# vim: tabstop=2 shiftwidth=2 expandtab textwidth=80 linebreak wrap
#
# make.rb
#
# Copyright 2018 David Rabkin
#
# This script creates symlinks from the home directory to any desired
# dotfiles in ~/dotfiles. Also it installs needfull packages.

require 'os'
require 'git'
require 'optparse'
require 'fileutils'
require 'English'

# Handles input parameters.
class Configuration
  def initialize
    ARGV << '-h' if ARGV.empty?
    @options = {}
    OptionParser.new do |opts|
      opts.banner = 'Usage: make.rb [options].'
      opts.on('-g', '--[no-]xorg',
              'Install X packages or not.') { |o| @options[:xorg] = o }
      opts.on('-p', '--pass pass',
              'Password for binary archive.') { |o| @options[:pass] = o }
    end.parse!

    raise 'Xorg option is not given' if @options[:xorg].nil?
    raise 'Pass option is not given' if @options[:pass].nil?
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
  attr_reader :font

  def initialize(cfg)
    @type = ''
    @test = ''
    @inst = ''
    @prec = ''
    @post = ''
    @font = ''

    # Packages without Xorg to install.
    @pkgs = %w[
      atop cmatrix cmus cowsay curl ffmpeg figlet htop imagemagick mc most ncdu
      npm python scrot tmux vim wget zsh zsh-syntax-highlighting
    ]

    # List of files/folders to symlink in homedir.
    @dotf = %w[bash_profile bashrc oh-my-zsh tmux.conf tmux vim vimrc zshrc]

    # List of files/folders to symlink in ~/.config.
    @conf = %w[mc]

    @font = %{
      mkdir -p ~/.fonts
      for f in inconsolata-g.otf pragmatapro.ttf; do
        if [[ ! -e ~/.fonts/$f ]]; then
          ln -s ~/dotfiles/bin/$f ~/.fonts
        fi
      done
      fc-cache -vf
    }

    configure(cfg)
  end

  def configure(cfg)
    return if cfg.pass.nil?

    # Runs pre-install for all OSs.
    system("rm -rf ~/dotfiles/bin && unzip -P #{cfg.pass} "\
           '~/dotfiles/bin.zip -d ~/dotfiles')

    return unless cfg.xorg?

    # Extends with Xorg related packages.
    (@pkgs << %w[
      conky dropbox feh firefox i3 i3blocks i3lock okular terminator
    ]).flatten!
    (@dotf << %w[i3 xinitrc]).flatten!
    (@conf << %w[conky terminator]).flatten!
  end

  private :configure
end

# Implements MacOS.
module MacOS
  def self.extended(mod)
    mod.type << 'MacOS'
    mod.prec << %{
      export HOMEBREW_CASK_OPTS="--appdir=/Applications"
      if hash brew &> /dev/null; then
        echo "Homebrew already installed."
      else
        ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
      fi
      brew cask upgrade
      brew cleanup && brew cask cleanup
      for f in inconsolata-g.otf pragmatapro.ttf; do
        if [[ ! -e ~/Library/Fonts/$f ]]; then
          cp ~/dotfiles/bin/$f ~/Library/Fonts/
        fi
      done
    }
    (
      mod.pkgs << %w[
        docker dropbox fonts-inconsolata firefox fonts-font-awesome fortune
        glances google-chrome iterm2 keepassxc keepingyouawake lolcat nmap pry
        sublime-text telegram tunnelblick virtualbox vox youtube-dl
      ]
    ).flatten!
    mod.test << 'brew ls --versions %s >/dev/null 2>&1'
    mod.inst << 'brew install %s || brew cask install %s'
    mod.post << 'sudo easy_install pip'
  end
end

# Implements FreeBSD.
module FreeBSD
  def self.extended(mod)
    mod.type << 'FreeBSD'
    (
      mod.pkgs << %w[
        inconsolata-ttf font-awesome fortune-mod-freebsd-classic py27-pip
        rubygem-pry-rails rubygem-lolcat youtube_dl
      ]
    ).flatten!
    mod.test << 'pkg info %s >/dev/null 2>&1'
    mod.inst << 'sudo pkg install -y %s'
    mod.post << mod.font << %{
      which glances || (cd /usr/ports/misc/py-glance && sudo make -DBATCH install clean)
    }
  end
end

# Implements Arch Linux.
module Arch
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
        alsa-utils fortune-mod fzf glances lolcat python-pip ruby-pry
        ttf-inconsolata ttf-inconsolata-g ttf-font-awesome youtube-dl
      ]
    ).flatten!
    mod.test << 'yaourt -Qs --nameonly %s >/dev/null 2>&1'
    mod.inst << 'yaourt -Sy --noconfirm %s'
    mod.post << mod.font << %{
      #sed -i 's/usr\/share/usr\/lib/g' ~/.i3/i3blocks.conf
    }
  end
end

# Implements Debian Linux.
module Debian
  def self.extended(mod)
    mod.type << 'Debian'
    mod.prec << %{
      sudo apt-get -y update
      sudo apt-get -y dist-upgrade
      curl -sL https://deb.nodesource.com/setup_9.x | sudo -E bash -
    }
    (
      mod.pkgs << %w[
        apcalc byobu fonts-inconsolata fonts-font-awesome fortune glances lolcat
        pry python-pip youtube-dl
      ]
    ).flatten!
    mod.test << 'dpkg -l %s >/dev/null 2>&1'
    mod.inst << 'sudo apt-get -y install %s'
    mod.post << mod.font
  end
end

# Implements RedHat Linux.
module RedHat
  def self.extended(mod)
    mod.type << 'RedHat'
    (
      mod.pkgs << %w[
        inconsolata-fonts fontawesome-fonts fortune glances lolcat pry
        youtube-dl
      ]
    ).flatten!
    mod.test << 'yum list installed %s >/dev/null 2>&1'
    mod.inst << 'sudo yum -y install %s'
    mod.post << mod.font
  end
end

# Implements Alpine Linux.
module Alpine
  def self.extended(mod)
    mod.type << 'Alpine'
    (
      mod.pkgs << %w[
        fonts-inconsolata fonts-font-awesome fortune glances lolcat py-pip
        pry youtube-dl
      ]
    ).flatten!
    mod.test << 'apk info %s >/dev/null 2>&1'
    mod.inst << 'sudo apk add %s'
    mod.post << mod.font
  end
end

# Defines current OS.
class CurrentOS
  def get
    return MacOS   if OS.mac?
    return FreeBSD if OS.freebsd?
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
    @os = OS.new(Configuration.new).extend(CurrentOS.new.get)
    @ndir = File.join(Dir.home, 'dotfiles')
    @odir = File.join(Dir.home, 'dotfiles-old')
  end

  def do
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
    %w[s_tui tmuxp].each do |p|
      chk = "python -c \"help('modules');\" | grep #{p} | wc -l | xargs"
      next if `#{chk}`.strip.eql? '1'
      system("pip install --user #{p}")
      puts("Unable to install #{p}.") unless $CHILD_STATUS.exitstatus > 0
    end

    # Installs Ruby packages.
    %w[video_transcoding].each do |p|
      chk = "gem list -i #{p}"
      next if `#{chk}`.strip.eql? 'true'
      system("gem install #{p}")
      puts("Unable to install #{p}.") unless $CHILD_STATUS.exitstatus > 0
    end

    # Installs NoJS packages.
    %w[gtop].each do |p|
      system("npm list -g #{p}")
      next unless $CHILD_STATUS.exitstatus
      system("npm install #{p}")
      puts("Unable to install #{p}.") unless $CHILD_STATUS.exitstatus > 0
    end

    puts('Bye-bye.')
  end
end

Installer.new.do
