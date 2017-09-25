#!/usr/bin/env ruby
# vim: tabstop=2 shiftwidth=2 expandtab textwidth=80 linebreak wrap
#
# make.rb
#
# Copyright 2017 David Rabkin
#
# This script creates symlinks from the home directory to any desired
# dotfiles in ~/dotfiles. Also it installs needfull packages.

require 'os'
require 'git'
require 'optparse'
require 'fileutils'
require 'English'

# Handles parameters.
class Configuration
  def initialize
    ARGV << '-h' if ARGV.empty?
    @options = {}
    OptionParser.new do |opts|
      opts.banner = 'Usage: make.rb [options].'
      opts.on('-g', '--[no-]xorg',
              'Install X packages or not.') { |o| @options[:xorg] = o }
    end.parse!

    raise 'Xorg option is not given' if @options[:xorg].nil?
  end

  def xorg?
    @options[:xorg]
  end
end

# Base class for definition of multiple OS.
class OS
  def configure(cfg)
    return unless cfg.xorg?

    # Extends with Xorg related packages.
    @pkgs += %w[conky feh i3 i3blocks i3lock]
    @dotf += %w[i3 xinitrc]
    @conf += %w[conky]
  end

  def initialize(cfg)
    # Packages without Xorg to install.
    @pkgs = %w[
      apcalc cmatrix cmus cowsay fonts-font-awesome fonts-inconsolata fortune
      glances hddtemp hollywood htop imagemagick lolcat mc most python scrot
      tmux zsh zsh-syntax-highlighting
    ]

    # List of files/folders to symlink in homedir.
    @dotf = %w[bash_profile bashrc oh-my-zsh tmux.conf tmux vim vimrc zshrc]

    # List of files/folders to symlink in ~/.config.
    @conf = %w[mc]

    configure(cfg)
  end

  def packages
    raise NotImplementedError, 'Implement packages() in a child class'
  end

  def installed?(_)
    raise NotImplementedError, 'Implement installed?() in a child class'
  end

  def install(_)
    raise NotImplementedError, 'Implement install() in a child class'
  end

  def post_install
    raise NotImplementedError, 'Implement post-install() in a child class'
  end
end

# Implements MacOS.
class MacOS < OS
  def initialize(cfg)
    super(cfg)
  end

  def packages
    @pkgs
  end

  def installed?(pkg)
    "brew ls --versions #{pkg} >/dev/null 2>&1"
  end

  def install(pkg)
    "su admin -c \"brew install #{pkg}\""
  end

  def post_install
    'su admin -c "sudo easy_install pip"'
  end
end

#os = MacOS.new(Configuration.new)
#os.packages.each do |p|
#  puts os.installed?(p) + ' : ' + os.install(p)
#end

# Actually does the job.
class Installer
  def initialize(cfg)
    # Packages without Xorg to install.
    pkgs = %w[
      apcalc cmatrix cmus cowsay fonts-font-awesome fonts-inconsolata fortune
      glances hddtemp hollywood htop imagemagick lolcat mc most python scrot
      tmux zsh zsh-syntax-highlighting
    ]

    # List of files/folders to symlink in homedir.
    @dotf = %w[bash_profile bashrc oh-my-zsh tmux.conf tmux vim vimrc zshrc]

    # List of files/folders to symlink in ~/.config.
    @conf = %w[mc]

    # Extends with Xorg related packages.
    if cfg.xorg?
      pkgs  += %w[conky feh i3 i3blocks i3lock]
      @dotf += %w[i3 xinitrc]
      @conf += %w[conky]
    end

    # [<packages list>, <existence command>, <install command>,
    # <post-install command>]
    @osdb = {
      darwin: ([
        pkgs,
        'brew ls --versions %s >/dev/null 2>&1',
        'su admin -c "brew install %s"',
        'su admin -c "sudo easy_install pip"'
      ] if OS.mac?),
      freebsd: ([
        pkgs
          .map { |x| x == 'lolcat' ? 'rubygem-lolcat' : x }
          .push('py27-pip'),
        'pkg info %s >/dev/null 2>&1',
        'sudo pkg install -y %s',
        ''
      ] if OS.freebsd?),
      archlinux: ([
        pkgs
          .map { |x| x == 'fortune' ? 'fortune-mod' : x }
          .map { |x| x == 'fonts-inconsolata' ? 'ttf-inconsolata' : x }
          .map { |x| x == 'fonts-font-awesome' ? '' : x },
        'pacman -Qs %s >/dev/null 2>&1',
        'sudo pacman -Sy %s',
        'sed -i \'s/usr\/share/usr\/lib/g\' ~/.i3/i3blocks.conf; ' \
          'yaourt -Sy ttf-font-awesome'
      ] if OS.linux? && File.file?('/etc/arch-release')),
      debian: ([
        pkgs.push('python-pip'),
        'dpkg -l %s >/dev/null 2>&1',
        'sudo apt-get -y install %s',
        ''
      ] if OS.linux? && File.file?('/etc/debian_version')),
      redhat: ([
        pkgs,
        'yum list installed %s >/dev/null 2>&1',
        'sudo yum -y install %s',
        ''
      ] if OS.linux? && File.file?('/etc/redhat-release')),
      alpine: ([
        pkgs.push('py-pip'),
        'apk info %s >/dev/null 2>&1',
        'sudo apk add %s',
        ''
      ] if OS.linux? && File.file?('/etc/alpine-release'))
    }.reject { |_, v| v.nil? }

    @ndir = File.join(Dir.home, 'dotfiles')
    @odir = File.join(Dir.home, 'dotfiles-old')
  end

  def pkgs
    @osdb.values[0][0]
  end

  def test(pkg)
    @osdb.values[0][1].dup % pkg
  end

  def install(pkg)
    @osdb.values[0][2].dup % pkg
  end

  def post_install_cmd
    @osdb.values[0][3]
  end

  def os
    @osdb.keys[0]
  end

  def do
    puts "Hello #{os}: #{pkgs}: #{@dotf}."

    # Install packages.
    pkgs.each do |p|
      # Tests if a package is installed.
      system test(p)

      # Installs new packages.
      if $CHILD_STATUS.exitstatus > 0
        puts "Install: #{p}."
        system install(p)
      else
        puts "#{p} is already installed."
      end
    end

    # Creates directory for existing dot files.
    FileUtils.mkdir_p(@odir)

    # Moves any existing dotfiles in homedir to dotfiles_old directory,
    # then creates symlinks from the homedir to any files in the ~/dotfiles
    # directory specified in $files.
    @dotf.each do |f|
      src = File.join(Dir.home, '.' + f)
      dst = File.join(@odir, '.' + f)

      if File.exist?(src)
        puts "mv #{src}->#{dst}"
        File.rename(src, dst)
      end

      FileUtils.ln_s(File.join(@ndir, f), src, force: true)
    end

    # Handles ~/.config in similar way.
    FileUtils.mkdir_p(File.join(@odir, '.config'))
    @conf.each do |f|
      src = File.join(Dir.home, '.config', f)
      dst = File.join(@odir, '.config', f)

      if File.exist?(src)
        puts "mv #{src}->#{dst}"
        File.rename(src, dst)
      end

      FileUtils.ln_s(File.join(@ndir, f), src, force: true)
    end

    system post_install_cmd unless post_install_cmd.to_s.empty?

    # Sets the default shell to zsh if it isn't currently set to zsh.
    sh = ENV['SHELL']
    unless shell.eql? `which zsh`.strip
      system 'chsh -s $(which zsh)'
      puts "Unable to switch #{sh} to zsh." unless $CHILD_STATUS.exitstatus > 0
    end

    # Clones oh-my-zsh repository from GitHub.
    dir = File.join(@ndir, 'oh-my-zsh')
    src = 'https://github.com/robbyrussell/oh-my-zsh'
    Git.clone(src, dir) unless Dir.exist?(dir)

    # Clones tpm plugin from GitHub.
    dir = File.join(@ndir, 'tmux', 'plugins', 'tpm')
    Git.clone('https://github.com/tmux-plugins/tpm', dir) unless Dir.exist?(dir)

    # Installs tmux session manager.
    if `python -c "help('modules');" | grep tmuxp | wc -l | xargs`.strip.eql? 0
      system 'pip install --user tmuxp'
      puts 'Unable to install tmuxp.' unless $CHILD_STATUS.exitstatus > 0
    end

    # Installs transcode-video.
    if `gem list -i video_transcoding`.strip.eql? 'false'
      system 'sudo gem install video_transcoding'
    else
      system 'sudo gem update video_transcoding'
    end

    puts 'Bye-bye.'
  end
end

Installer.new(Configuration.new).do
