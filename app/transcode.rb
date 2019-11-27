#!/usr/bin/env ruby
# frozen_string_literal: true

# vim: tabstop=2 shiftwidth=2 expandtab textwidth=80 linebreak wrap
#
# Copyright 2018-present David Rabkin
#
# Transcodes any video file to m4v format.

require 'colorize'
require 'English'
require 'fileutils'
require 'optparse'
require 'set'
require 'terminal-table'
require_relative 'utils'

# Handles input parameters.
class Configuration
  attr_reader :files
  DIC = [
    ['-a', '--act', 'Real encoding.', nil, :act],
    ['-s', '--sca', 'Scan files at the directory.', nil, :sca],
    ['-d', '--dir dir', 'Directory to transcode.', String, :dir],
    ['-o', '--out out', 'Directory to output.', String, :out],
    ['-u', '--aud aud', 'Audio stream numbers.', Array, :aud],
    ['-t', '--sub sub', 'Subtitle stream numbers.', Array, :sub],
    ['-w', '--wid wid', 'Width of the table.', Integer, :wid]
  ].freeze
  EXT = %i[avi flv mkv mp4].map(&:to_s).join(',').freeze

  def initialize
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
    validate_val(aud, :aud)
    validate_val(sub, :sub)
    raise "Width of the table should exeeds 14 symbols: #{wid}." if wid < 15
  end

  def validate_dir
    if dir.nil?
      @options[:dir] = Dir.pwd
    else
      raise "No such directory: #{dir}." unless File.directory?(dir)

      @options[:dir] = File.expand_path(dir)
    end
    @options[:out] = File.expand_path('~') if out.nil?
  end

  def validate_files
    @files = Dir[dir + "/*.{#{EXT}}"]
    @files += Dir.glob('*').select { |f| File.directory? f }
    raise "#{dir} doesn't have #{EXT} files or directories." if @files.empty?

    bad = @files.reject { |f| File.readable?(f) }
    raise "Unable to read #{bad} files." unless bad.empty?
  end

  def validate_val(val, tag)
    f = @files.size
    (@options[tag] = Array.new(f, '0')).nil? || return if val.nil?
    s = val.size
    if s == 1
      @options[tag] = Array.new(f, val.first)
    else
      raise "#{tag} and files do not suit #{s} != #{f}." unless s == f
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

  def out
    @options[:out]
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
  def initialize(act, tit, wid)
    @act = act
    @tit = tit
    @tbl = wid
    @ttl = @tbl - 4
    @str = (@tbl - 7) / 2
    @row = []
    @tim = Timer.new
    @sta = { converted: 0, failed: 0 }
  end

  def add(file, aud, sub, res)
    @row << [
      Utils.trim(File.basename(file), @str),
      { value: aud, alignment: :right },
      { value: sub, alignment: :right }
    ]
    @sta[res ? :converted : :failed] += 1
  end

  def table
    Terminal::Table.new(
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

  def do
    puts table
    final
  end

  def stat
    out = ''
    @sta.each do |k, v|
      out += ' ' + v.to_s + ' ' + k.to_s + ',' if v.positive?
    end
    out.chop
  end

  def final
    msg = "#{@act ? 'Real' : 'Test'}:#{stat} in #{@tim.read}."
    msg = Utils.trim(msg, @ttl)
    puts "| #{msg}#{' ' * (@ttl - msg.length)} |\n+-#{'-' * @ttl}-+"
  end
end

# Transcodes any video file to m4v format.
class Transcoder
  def initialize
    @cfg = Configuration.new
    @rep = Reporter.new(@cfg.act?, @cfg.dir, @cfg.wid)
  end

  def scan
    @cfg.files.each do |file|
      puts "---------- #{File.basename(file)} ----------"
      puts `transcode-video --scan #{file}`
    end
  end

  # Converts files, aud and sub arrays to hash 'file->[aud, sub]'.
  def data
    @data ||= @cfg.files.zip([@cfg.aud, @cfg.sub].transpose).to_h
  end

  def cmd(file, aud, sub)
    c = 'transcode-video --m4v --no-log --preset veryslow'\
        " --output #{@cfg.out}"
    c += " --main-audio #{aud}" unless aud == '0'
    c += " --burn-subtitle #{sub}" unless sub == '0'
    c + " #{file} 2>&1"
  end

  # Runs command and prints output instantly. Returns true on success.
  def run(cmd)
    puts "Run: #{cmd}."
    IO.popen(cmd).each do |line|
      puts line.chomp
    end.close
    !$CHILD_STATUS.exitstatus.positive?
  end

  def do
    scan && return if @cfg.sca?
    data.each do |file, audsub|
      res = @cfg.act? ? run(cmd(file, audsub[0], audsub[1])) : true
      @rep.add(file, audsub[0], audsub[1], res)
    end
    @rep.do
  end
end

Transcoder.new.do
