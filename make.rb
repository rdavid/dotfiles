#!/usr/bin/env ruby
# frozen_string_literal: true

# vi:ts=2 sw=2 tw=79 et lbr wrap
# Copyright 2017 by David Rabkin
#
# This script creates symlinks from the home directory to any desired
# dotfiles in ~/dotfiles. Also it installs needfull packages.
#
# For MacOS run without X and with the password for binary:
#   make --no-xorg -pass pass

require 'English'
require 'git'
require 'fileutils'
require 'optparse'
require 'os'
require 'pidfile'

# Handles input parameters.
class Configuration
  DIC = [
    ['-g', '--[no-]xorg', 'Install X packagest.', :xorg],
    ['-p', '--pass pass', 'Password for binary.', :pass]
  ].freeze

  def initialize # rubocop:disable Metrics/AbcSize
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
  attr_reader :type, :test, :inst, :prec, :post, :pkgs, :dotf, :conf, :sudo

  def initialize(cfg) # rubocop:disable Metrics/MethodLength
    @type = +''
    @test = +''
    @inst = +''
    @post = +''
    @prec = +''
    @sudo = +''

    # Packages without Xorg to install.
    @pkgs = %w[
      bat cairo-devel cmake cmatrix cmus cowsay cppcheck curl ctags exa f3
      fdupes ffmpeg figlet fortune fzf gawk git-delta gnupg handbrake htop
      imagemagick lynx mc mosh most ncdu npm nnn python qrencode redo ripgrep
      shellcheck syncthing tmux vifm vim wget zsh zsh-syntax-highlighting
      yamllint
    ]

    # List of files/folders to symlink in homedir.
    @dotf = %w[
      bash_profile bashrc fzf.bash fzf.zsh gitconfig oh-my-zsh tmux.conf tmux
      vim vimrc zshrc
    ]

    # List of files/folders to symlink in ~/.config.
    @conf = %w[mc vifm]

    # For MacOS run '--no-xorg --pass'.
    unless cfg.pass.nil?
      @prec << %(
        rm -rf ~/dotfiles/bin
        unzip -P #{cfg.pass} ~/dotfiles/bin.zip -d ~/dotfiles
        SRC="$HOME/dotfiles/bin/zsh_history"
        HST="$HOME/.zsh_history"
        TMP='/tmp/merged.tmp'
        if [ -f "$HST" ]; then
          ~/dotfiles/app/merge_history.sh "$SRC" "$HST" > "$TMP"
          cp -f "$TMP" "$HST" && rm -f "$TMP"
        else
          cp "$SRC" "$HST"
        fi
      )
    end
    xconfigure if cfg.xorg?
  end

  private

  def xconfigure # rubocop:disable Metrics/MethodLength
    @prec << %(
      mkdir -p ~/.fonts
      for f in inconsolata-g.otf pragmatapro.ttf; do
        if [[ ! -e ~/.fonts/$f ]]; then
          ln -s ~/dotfiles/bin/$f ~/.fonts
        fi
      done
      fc-cache -vf
    )
    # Extends with Xorg related packages.
    (@pkgs << %w[
      acpi feh blueman firefox font-awesome google-chrome i3 i3blocks
      i3lock keepassxc kitty lm_sensors mpv network-manager-applet okular
      sublime-text xautolock xkill xmodmap xrdp xrandr
    ]).flatten!
    (@dotf << %w[i3 xinitrc]).flatten!
    (@conf << %w[kitty]).flatten!
  end
end

# Implements MacOS.
module MacOS
  DIC = {
  }.freeze

  def self.pkgs(mod)
    (
      mod.pkgs << %w[
        aerial appcleaner coreutils disk-inventory-x docker feh firefox hadolint
        iterm2 google-chrome keepassxc keepingyouawake kitty launchbar librsync
        lolcat mpv nmap plex plexamp spectacle spotifree spotify sublime-text
        telegram vanilla virtualbox watch xquartz
      ]
    ).flatten!
      .map! { |i| DIC[i.to_sym].nil? ? i : DIC[i.to_sym] }
  end

  def self.prec(mod) # rubocop:disable Metrics/MethodLength
    mod.prec << %(
      for f in inconsolata-g.otf pragmatapro.ttf; do
        if [[ ! -e ~/Library/Fonts/$f ]]; then
          cp ~/dotfiles/bin/$f ~/Library/Fonts/
        fi
      done
      export HOMEBREW_CASK_OPTS="--appdir=/Applications"
      if hash brew &> /dev/null; then
        echo 'Homebrew already installed.'
      else
        link='https://raw.githubusercontent.com/Homebrew/install/master/install'
        ruby -e "$(curl -fsSL $(link))"
      fi
      brew update && brew upgrade && brew upgrade --cask && brew cleanup
    )
  end

  def self.extended(mod)
    pkgs(mod)
    prec(mod)
    mod.sudo << 'sudo'
    mod.type << 'MacOS'
    # MacOS is installed without Xorg, so some graphic settings are duplicated.
    mod.conf << 'kitty'
    mod.test << %(
      brew ls --versions %s >/dev/null 2>&1|| \
        brew cask ls --versions %s >/dev/null 2>&1
    )
    mod.inst << 'brew install %s; brew cask install %s'
  end
end

# Implements FreeBSD.
module FreeBSD
  DIC = {
    fortune: 'fortune-mod-freebsd-classic',
    imagemagick: 'imagemagick7',
    qrencode: 'py36-qrcode',
    shellcheck: 'hs-ShellCheck',
    yamllint: 'py36-yamllint'
  }.freeze

  def self.pkgs(mod)
    (
      mod.pkgs << %w[
        py36-pip py36-setuptools rubygem-lolcat unzip zip
      ]
    ).flatten!
      .map! { |i| DIC[i.to_sym].nil? ? i : DIC[i.to_sym] }
  end

  def self.extended(mod)
    pkgs(mod)
    mod.sudo << 'sudo'
    mod.inst << 'sudo pkg install -y %s'
    mod.test << 'pkg info %s >/dev/null 2>&1'
  end
end

# Implements OpenBSD.
module OpenBSD
  DIC = {
    bat: '',
    f3: '',
    fortune: '',
    i3blocks: '',
    'google-chrome': 'chromium',
    handbrake: '',
    imagemagick: 'ImageMagick',
    kitty: '',
    npm: 'node',
    'sublime-text': '',
    'visual-studio-code': '',
    'zsh-syntax-highlighting': ''
  }.freeze

  def self.pkgs(mod)
    (
      mod.pkgs << %w[
        coreutils py-pip terminator
      ]
    ).flatten!
      .map! { |i| DIC[i.to_sym].nil? ? i : DIC[i.to_sym] }
  end

  def self.prec(mod)
    mod.prec << %(
      ln -sf ~/.xinitrc ~/.xsession
      doas rcctl enable xenodm
      cd ~ && git clone git://github.com/tghelew/i3blocks
      cd i3blocks && doas pkg_add gmake
      gmake clean all
      doas gmake install
      cd .. && rm -rf ~/3blocks
    )
  end

  def self.extended(mod)
    pkgs(mod)
    prec(mod)
    mod.sudo << 'doas'
    mod.type << 'OpenBSD'
    mod.conf << 'terminator'
    mod.inst << 'doas pkg_add %s'
    mod.test << 'which %s >/dev/null 2>&1'
  end
end

# Implements Arch Linux.
module Arch
  DIC = {
    fortune: 'fortune-mod',
    'font-awesome': 'ttf-font-awesome',
    handbrake: '',
    shellcheck: '',
    'sublime-text': 'sublime-text-dev',
    'visual-studio-code': 'visual-studio-code-bin'
  }.freeze

  def self.pkgs(mod)
    (
      mod.pkgs << %w[
        alsa-utils atop lolcat python-pip
      ]
    ).flatten!
      .map! { |i| DIC[i.to_sym].nil? ? i : DIC[i.to_sym] }
  end

  def self.prec(mod)
    mod.prec << %(
      if [ ! $(command -v yay >/dev/null 2>&1) ]; then
        sudo pacman -Sy --noconfirm base-devel
        git clone https://aur.archlinux.org/yay.git /tmp/yay
        cd /tmp/yay
        makepkg -si --noconfirm
        cd -
      fi
      yay -Syauu --noconfirm
    )
  end

  def self.extended(mod)
    pkgs(mod)
    prec(mod)
    mod.type << 'Arch'
    mod.inst << 'yay -Sy --noconfirm %s'
    mod.test << 'yay -Qs %s >/dev/null 2>&1'
    mod.post << %(
      #sed -i 's/usr\/share/usr\/lib/g' ~/.i3/i3blocks.conf
    )
  end
end

# Implements Debian Linux.
module Debian
  DIC = {
    'font-awesome': 'fonts-font-awesome'
  }.freeze

  def self.pkgs(mod)
    (
      mod.pkgs << %w[
        apcalc atop byobu lolcat python-pip net-tools
      ]
    ).flatten!
      .map! { |i| DIC[i.to_sym].nil? ? i : DIC[i.to_sym] }
  end

  def self.prec(mod)
    mod.prec << %(
      sudo apt-get -y update
      sudo apt-get -y dist-upgrade
      curl -sL https://deb.nodesource.com/setup_9.x | sudo -E bash -
    )
  end

  def self.extended(mod)
    pkgs(mod)
    prec(mod)
    mod.sudo << 'sudo'
    mod.type << 'Debian'
    mod.inst << 'sudo apt-get -y install %s'
    mod.test << 'dpkg -l %s >/dev/null 2>&1'
  end
end

# Implements RedHat Linux.
module RedHat
  DIC = {
    'font-awesome': 'fontawesome-fonts',
    fortune: 'fortune-mod',
    'google-chrome': 'google-chrome-stable',
    imagemagick: 'ImageMagick',
    redo: '',
    shellcheck: 'ShellCheck'
  }.freeze

  def self.pkgs(mod)
    (
      mod.pkgs << %w[
        librsync-devel lolcat python3-devel util-linux-user
      ]
    ).flatten!
      .map! { |i| DIC[i.to_sym].nil? ? i : DIC[i.to_sym] }
  end

  def self.rpmfusion(mod)
    mod.prec << %(
      if ! dnf list installed | grep rpmfusion-free >/dev/null; then
        sudo dnf -y install \
          https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
        sudo dnf -y install \
          https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
      fi
    )
  end

  def self.repositories(mod)
    mod.prec << %(
      if ! dnf list installed | grep fedora-workstation-repositories >/dev/null; then
        sudo dnf install -y fedora-workstation-repositories
        sudo dnf config-manager --set-enabled google-chrome
      fi
      if ! dnf repolist enabled | grep sublime-text >/dev/null; then
        sudo rpm -v --import https://download.sublimetext.com/sublimehq-rpm-pub.gpg
        sudo dnf config-manager --add-repo https://download.sublimetext.com/rpm/stable/x86_64/sublime-text.repo
      fi
    )
  end

  def self.prec(mod)
    rpmfusion(mod)
    repositories(mod)
    mod.prec << %(
      dnf -y check-update
      sudo dnf -y upgrade --refresh
    )
  end

  def self.extended(mod)
    pkgs(mod)
    prec(mod)
    mod.sudo << 'sudo'
    mod.type << 'RedHat'
    mod.inst << 'sudo dnf -y install %s'
    mod.test << 'dnf list installed | grep %s >/dev/null 2>&1'
  end
end

# Implements Alpine Linux.
module Alpine
  DIC = {
    bat: '',
    cmatrix: '',
    cowsay: '',
    f3: '',
    handbrake: '',
    most: '',
    npm: 'nodejs nodejs-npm',
    nnn: '',
    'zsh-syntax-highlighting': ''
  }.freeze

  def self.pkgs(mod)
    (
      mod.pkgs << %w[
        atop linux-headers musl-dev python-dev py-pip
      ]
    ).flatten!
      .map! { |i| DIC[i.to_sym].nil? ? i : DIC[i.to_sym] }
  end

  def self.prec(mod)
    mod.prec << %(
      sudo apk update
      sudo apk upgrade
    )
  end

  def self.extended(mod)
    pkgs(mod)
    prec(mod)
    mod.sudo << 'sudo'
    mod.type << 'Alpine'
    mod.inst << 'sudo apk add %s'
    mod.test << 'apk -e info %s >/dev/null 2>&1'
  end
end

# Defines current OS.
class CurrentOS
  ARCH = ['/etc/arch-release', '/etc/artix-release'].freeze
  def self.get # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity, Metrics/AbcSize
    return MacOS if OS.mac?
    return FreeBSD if OS.freebsd?
    return OpenBSD if OS.host_os =~ /openbsd/
    return Arch if OS.linux? && ARCH.detect { |i| File.file?(i) }
    return Debian if OS.linux? && File.file?('/etc/debian_version')
    return RedHat if OS.linux? && File.file?('/etc/redhat-release')
    return Alpine if OS.linux? && File.file?('/etc/alpine-release')

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

  def do # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity, Metrics/AbcSize, Metrics/MethodLength
    # Sort should be first, reject! returns nil if there is no empty.
    @os.pkgs.sort!.reject!(&:empty?)
    puts("Hello #{@os.type}: #{@os.pkgs}: #{@os.dotf}: #{@os.conf}.")

    # Runs pre-install commands.
    system(@os.prec) unless @os.prec.empty?

    # Install packages.
    @os.pkgs.each do |p|
      # Tests if a package is installed.
      system(@os.test.gsub('%s', p))

      # Installs new packages.
      if $CHILD_STATUS.exitstatus.positive?
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
      src = File.join(Dir.home, ".#{f}")
      dst = File.join(@odir, ".#{f}")
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
    system(@os.post) unless @os.post.empty?

    # Sets the default shell to zsh if it isn't currently set to zsh.
    sh = ENV['SHELL']
    unless sh.eql? `which zsh`.strip
      system('chsh -s $(which zsh)')
      rc = $CHILD_STATUS.exitstatus
      puts("Unable to switch #{sh} to zsh.") unless rc.positive?
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
      },
      {
        src: 'https://github.com/w0rp/ale.git',
        dst: File.join(@ndir, 'vim', 'pack', 'git-plugins', 'start', 'ale')
      }
    ].each do |i|
      Git.clone(i[:src], i[:dst]) unless Dir.exist?(i[:dst])
    end
    sudo = @os.sudo

    # Installs Python packages,
    # rdiff_backup depends on wheel.
    # speedtest-cli depends on matplotlib.
    %w[
      glances matplotlib pss wheel rdiff_backup s_tui speedtest-cli tmuxp
      youtube_dl
    ].each do |p|
      chk = "python -c \"help('modules');\" | grep #{p} | wc -l | xargs"
      next if `#{chk}`.strip.eql? '1'

      system("pip install --user #{p}")
      puts("Unable to install #{p}.") unless $CHILD_STATUS.exitstatus.positive?
    end

    # Updates all Python packages.
    system('pip list --outdated --format=freeze |'\
           'grep -v \'^\-e\' |'\
           'cut -d = -f 1 |'\
           'xargs -n1 pip install -U --user')
    puts('Unable to update Python.') unless $CHILD_STATUS.exitstatus.positive?

    # Installs Ruby packages.
    %w[
      English pry pry-doc renamr rubocop rubygems-update transcode
    ].each do |p|
      chk = "gem list -i #{p}"
      next if `#{chk}`.strip.eql? 'true'

      system("#{sudo} gem install #{p}")
      puts("Unable to install #{p}.") unless $CHILD_STATUS.exitstatus.positive?
    end
    system("#{sudo} update_rubygems && #{sudo} gem update --system")
    puts('Unable to update Ruby.') unless $CHILD_STATUS.exitstatus.positive?

    # Installs NoJS packages.
    %w[
      gtop
    ].each do |p|
      system("npm list -g #{p}")
      next unless $CHILD_STATUS.exitstatus

      system("#{sudo} npm install #{p}")
      puts("Unable to install #{p}.") unless $CHILD_STATUS.exitstatus.positive?
    end
    system("#{sudo} npm update")
    puts('Unable to update NodeJS.') unless $CHILD_STATUS.exitstatus.positive?
    puts('Bye-bye.')
  end
end

PidFile.new
Installer.new.do
