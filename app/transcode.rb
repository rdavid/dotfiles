#!/usr/bin/env ruby
# frozen_string_literal: true

# vim: tabstop=2 shiftwidth=2 expandtab textwidth=80 linebreak wrap
#
# Copyright 2018-present David Rabkin
#
# Transcodes any video file to m4v format.

require 'set'
require 'colorize'
require 'optparse'
require 'fileutils'
require 'terminal-table'
require_relative 'utils'

# Handles input parameters.
class Configuration
  attr_reader :files
  DIC = [
    ['-a', '--act', 'Real encoding.', nil, :act],
    ['-c', '--sca', 'Scan first file.', nil, :sca],
    ['-d', '--dir dir', 'Directory to transcode.', String, :dir],
    ['-u', '--aud aud', 'Audio stream numbers.', Array, :aud],
    ['-s', '--sub sub', 'Subtitle stream numbers.', Array, :sub],
    ['-w', '--wid wid', 'Width of the table.', Integer, :wid]
  ].freeze
  EXT = %i[avi flv mkv mp4].map(&:to_s).join(',').freeze

  def initialize
    ARGV << '-h' if ARGV.empty?
    @options = {}
    OptionParser.new do |o|
      o.banner = "Usage: #{File.basename($PROGRAM_NAME)} [options]."
      DIC.each { |f, p, d, t, k| o.on(f, p, t, d) { |i| @options[k] = i } }
    end.parse!
    validate
  end

  def validate
    validate_dir
    validate_files
    validate_audio
    validate_subtitles
    raise "Width of the table should exeeds 14 symbols: #{wid}." if wid < 15
  end

  def validate_dir
    raise 'Directory option is not given.' if dir.nil?
    raise "No such directory: #{dir}." unless File.directory?(dir)
  end

  def validate_files
    @files = Dir[dir + "/*.{#{EXT}}"].sort
    raise "Directory #{dir} doesn't have #{EXT} files." if @files.empty?

    bad = @files.reject { |f| File.readable?(f) }
    raise "Unable to read #{bad} files." unless bad.empty?
  end

  def validate_audio
    return if aud.nil?

    f = @files.size
    a = aud.size
    if a == 1
      @options[:aud] = Array.new(f, aud.first)
    else
      raise "Aud and files do not suit #{a} != #{f}." unless a == f
    end
  end

  def validate_subtitles
    return if aud.nil?

    f = @files.size
    s = sub.size
    if s == 1
      @options[:sub] = Array.new(f, sub.first)
    else
      raise "Sub and files do not suit #{s} != #{f}." unless s == f
    end
  end

  def act?
    @options[:act]
  end

  def sca?
    @options[:sca]
  end

  def dir
    @options[:dir]
  end

  def aud
    @options[:aud]
  end

  def sub
    @options[:sub]
  end

  def wid
    if @options[:wid].nil?
      # Reads current terminal width.
      wid = `tput cols`
      wid.to_s.empty? ? 79 : wid.to_i
    else
      @options[:wid].to_i
    end
  end
end

# Formats and prints output data.
class Reporter
  def initialize(tit, wid)
    @tit = tit
    @tbl = wid
    @ttl = @tbl - 4
    @str = (@tbl - 7) / 2
    @row = []
  end

  def add(nam, aud, sub)
    @row << [Utils.trim(nam, @str), aud, sub]
  end

  def do
    puts Terminal::Table.new(
      title: Utils.trim(@tit, @ttl),
      headings: [
        { value: 'file', alignment: :center },
        { value: 'audio', alignment: :center },
        { value: 'subtitles', alignment: :center }
      ],
      rows: @row,
      style: { width: @tbl }
    )
  end
end

# Transcodes any video file to m4v format.
class Transcoder
  def initialize
    @cfg = Configuration.new
    @sta = { converted: 0, failed: 0 }
    @rep = Reporter.new(@cfg.dir, @cfg.wid)
    @tim = Timer.new
  end

  def scan
    @cfg.files.each do |file|
      puts "---------- #{File.basename(file)} ----------"
      v = `transcode-video --scan #{file}`
      puts v
    end
  end

  def do
    scan && return if @cfg.sca?
    @cfg.files.each do |file|
      @rep.add(file, '0', '0')
    end
    @rep.do
    puts "#{@cfg.act? ? 'Real' : 'Simulation'}:"\
         " #{@sta[:converted]} converted,"\
         " #{@sta[:failed]} failed in"\
         " #{@tim.read}."
  end
end

Transcoder.new.do
