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
require "git"
require 'fileutils'

class Installer

  def initialize()

    # Packages to install.
    @pkgs = [
      'zsh', 'tmux', 'most', 'python', 'cowsay', 'htop', 'fortune',
      'lolcat', 'feh', 'conky', 'scrot', 'imagemagick', 'i3', 'i3lock',
      'cmatrix', 'hollywood', 'hddtemp', 'glances', 'htop',
      'fonts-inconsolata'
    ]

    # [<packages list>, <existence command>, <install command>]
    @osdb = {
        :'darwin'    => ([@pkgs,
                          "brew ls --versions %s >/dev/null 2>&1",
                          "su admin -c \"brew install %s\"; " +
                          "su admin -c \"sudo easy_install pip\""
                         ] if OS.mac?),
        :'freebsd'   => ([@pkgs
                         .map{|x|x == 'lolcat' ? 'rubygem-lolcat' : x}
                         .push('py27-pip'),
                          "pkg info %s >/dev/null 2>&1",
                          "sudo pkg install -y %s"
                         ] if OS.freebsd?),
        :'archlinux' => ([@pkgs
                          .map{|x|x == 'fortune' ? 'fortune-mod' : x},
                          "pacman -Qs %s >/dev/null 2>&1",
                          "sudo pacman -Sy %s"
                         ] if OS.linux? && File.file?("/etc/arch-release")),
        :'debian'    => ([@pkgs
                          .push('python-pip'),
                          "dpkg -l %s >/dev/null 2>&1",
                          "sudo apt-get -y install %s"
                         ] if OS.linux? && File.file?("/etc/debian_version")),
        :'redhat'    => ([@pkgs,
                          "yum list installed %s >/dev/null 2>&1",
                          "sudo yum -y install %s"
                         ] if OS.linux? && File.file?("/etc/redhat-release"))
    }.reject { |k, v| v.nil? }

    # List of files/folders to symlink in homedir.
    @dotf = [
      'bashrc', 'bash_profile', 'vimrc', 'vim', 'zshrc', 'oh-my-zsh',
      'tmux.conf', 'tmux', 'xinitrc', 'i3'
    ]

    @ndir = File.join(Dir.home, "dotfiles")
    @odir = File.join(Dir.home, "dotfiles-old")
  end

  def pkgs
      @osdb.values[0][0]
  end

  def test(pkg)
      @osdb.values[0][1].dup % pkg
  end

  def install(pkgs)
      @osdb.values[0][2].dup % pkgs
  end

  def os
      @osdb.keys[0]
  end

  def do
    puts "Hello #{os}: #{pkgs}."

    # Tests if a package is installed.
    new_pkgs = Array.new
    pkgs.each do |pkg|
      system "#{test(pkg)}"
      new_pkgs.push(pkg) if $?.exitstatus > 0
    end

    # Installs needfull packages.
    cmd = install(new_pkgs.join(' ')) if new_pkgs.any?
    (puts "Install: #{cmd}."; system "#{cmd}") unless cmd.nil?

    # Creates directory for existing dot files.
    FileUtils.mkdir_p @odir

    # Moves any existing dotfiles in homedir to dotfiles_old directory,
    # then creates symlinks from the homedir to any files in the ~/dotfiles
    # directory specified in $files.
    @dotf.each do |name|
      src = File.join(Dir.home, '.' + name)
      dst = File.join(@odir, '.' + name)
      (puts "mv #{src}->#{dst}"; File.rename(src, dst)) if File.exist?(src)
      FileUtils.ln_s(File.join(@ndir, name), src, :force => true)
    end

    # Handles manually.
    src = File.join(Dir.home, '.config', 'conky1')
    dst = File.join(@odir, '.config', 'conky')
    (puts "mv #{src}->#{dst}"; File.rename(src, dst)) if File.exist?(src)
    FileUtils.ln_s(File.join(@ndir, 'conky1'), src, :force => true)

    # Sets the default shell to zsh if it isn't currently set to zsh.
    shell = ENV["SHELL"]
    unless (shell.eql? `which zsh`.strip)
      system('chsh -s $(which zsh)')
      puts("Unable to switch current #{shell} to zsh.") unless $?.exitstatus > 0
    end

    # Clones oh-my-zsh repository from GitHub.
    dir = File.join(@ndir, 'oh-my-zsh')
    Git.clone('https://github.com/robbyrussell/oh-my-zsh.git', dir) unless Dir.exist?(dir)

    # Clones tpm plugin from GitHub.
    dir = File.join(@ndir, 'tmux', 'plugins', 'tpm')
    Git.clone('https://github.com/tmux-plugins/tpm', dir) unless Dir.exist?(dir)

    # Installs tmux session manager.
    if (`python -c "help('modules');" | grep tmuxp | wc -l | xargs`.strip.eql? 0)
      system('pip install --user tmuxp')
      puts("Unable to install tmuxp.") unless $?.exitstatus > 0
    end

    # Installs transcode-video.
    if (`gem list -i video_transcoding`.strip.eql? 'false')
      system('sudo gem install video_transcoding')
    else
      system('sudo gem update video_transcoding')
    end

    puts "Bye-bye."
  end
end

Installer.new.do
