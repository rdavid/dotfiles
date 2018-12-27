#!/usr/bin/env ruby
# vim: tabstop=2 shiftwidth=2 expandtab textwidth=80 linebreak wrap
#
# clean.rb
#
# Copyright 2018 David Rabkin
#
# This script removes all files besides specific types in given directory.
#

require 'set'
require 'colorize'
require 'optparse'
require 'fileutils'
require 'terminal-table'
require_relative 'utils'

# Handles input parameters.
class Configuration
  DIC = [
    ['-a', '--act',     'Real renaming.',          :act],
    ['-r', '--rec',     'Passes recursively.',     :rec],
    ['-e', '--ext',     'File extention to keep.', :ext],
    ['-d', '--dir dir', 'Directory to rename.',    :dir],
    ['-w', '--wid wid', 'Width of the table.',     :wid]
  ].freeze

  def initialize
    ARGV << '-h' if ARGV.empty?
    @options = {}
    OptionParser.new do |o|
      o.banner = 'Usage: rename.rb [options].'
      DIC.each { |f, p, d, k| o.on(f, p, d) { |i| @options[k] = i } }
    end.parse!
    raise 'Directory option is not given.' if dir.nil?
    raise "No such directory: #{dir}." unless File.directory?(dir)
    raise "Width of the table should exeeds 14 symbols: #{wid}." if wid < 15
  end

  def act?; @options[:act] end
  def rec?; @options[:rec] end
  def ext; @options[:ext] end
  def dir;  @options[:dir] end
  def wid;  @options[:wid].nil? ? 79 : @options[:wid].to_i end
end

class RemoveAllButMP3Action < Action
  DIC = ['mp3', 'mp4']
  REM = 'REMOVETHEFILE'
  def do(src)
    return src if DIC.include?(File.extname(src).delete('.'))
    REM
  end
end

# Formats and prints output data.
class Reporter
  def initialize(dir, wid)
    @dir = dir
    @tbl = wid
    @ttl = @tbl - 4
    @str = (@tbl - 7) / 2
    @row = []
  end

  def add(lhs, rhs)
    @row << [Utils.trim(lhs, @str), Utils.trim(rhs, @str)]
  end

  def do
    puts Terminal::Table.new(
      title: Utils.trim(@dir, @ttl),
      headings: [
        { value: 'src', alignment: :center },
        { value: 'dst', alignment: :center }
      ],
      rows: @row,
      style: { width: @tbl }
    )
  end
end

# Renames file by certain rules.
class Renamer
  def initialize
    @cfg = Configuration.new
    @fac = ActionsFactory.new(@cfg)
    @sta = { moved: 0, unaltered: 0, removed:0, failed: 0 }
  end

  def move(dir, dat)
    rep = Reporter.new(dir, @cfg.wid)
    dat.each do |src, dst|
      if src == dst
        @sta[:unaltered] += 1
        rep.add(File.basename(src), '')
        next
      end
      begin
        FileUtils.mv(src, dst) if @cfg.act?
        @sta[:moved] += 1
        rep.add(File.basename(src), File.basename(dst))
      rescue StandardError => msg
        @sta[:failed] += 1
        rep.add(File.basename(src), msg)
      end
    end
    rep.do
  end

  def do_dir(dir)
    raise "No such directory: #{dir}." unless File.directory?(dir)

    dat = []
    act = @fac.produce(dir)
    (Dir.entries(dir) - ['.', '..']).sort.each do |nme|
      src = File.join(dir, nme)
      do_dir(src) if @cfg.rec? && File.directory?(src)
      act.each { |a| a.set(nme) }
      act.each { |a| break if (nme = a.do(nme)).nil? }
      dat << [src, File.join(dir, nme)] unless nme.nil?
    end
    move(dir, dat) if dat.any?
  end

  def stat_out
    out = ''
    @sta.each do |k, v|
      next unless v > 0
      out += ' ' + v.to_s + ' ' + k.to_s + ','
    end
    out.chop
  end

  def do
    tim = Timer.new
    do_dir(@cfg.dir)
    puts "#{@cfg.act? ? 'Real'.red : 'Test'.green}:#{stat_out} in #{tim.read}."
  end
end

Renamer.new.do
