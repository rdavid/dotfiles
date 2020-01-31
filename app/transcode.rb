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
require 'pidfile'
require 'set'
require 'shellwords'
require 'terminal-table'
require_relative 'utils'

# Handles input parameters.
class Configuration
  attr_reader :files
  DIC = [
    ['-a', '--act', 'Real encoding.', nil, :act],
    ['-s', '--sca', 'Scans files at the directory.', nil, :sca],
    ['-m', '--mp3', 'Converts files to mp3.', nil, :mp3],
    ['-d', '--dir dir', 'Directory to transcode.', String, :dir],
    ['-i', '--tit tit', 'Specific title by number.', Array, :tit],
    ['-o', '--out out', 'Directory to output.', String, :out],
    ['-u', '--aud aud', 'Audio stream numbers.', Array, :aud],
    ['-t', '--sub sub', 'Subtitle stream numbers.', Array, :sub],
    ['-w', '--wid wid', 'Width of the table.', Integer, :wid]
  ].freeze
  EXT = %i[avi flv m4v mkv mp4 webm].map(&:to_s).join(',').freeze

  def initialize
    @options = {}
    OptionParser.new do |o|
      o.banner = "Usage: #{File.basename($PROGRAM_NAME)} [options]."
      DIC.each { |f, p, d, t, k| o.on(f, p, t, d) { |i| @options[k] = i } }
    end.parse!
    find_dir
    find_fil
    validate
  end

  def find_dir
    if dir.nil?
      @options[:dir] = Dir.pwd
    else
      raise "No such directory: #{dir}." unless File.directory?(dir)

      @options[:dir] = File.expand_path(dir)
    end
    @options[:out] = File.expand_path(out.nil? ? '~' : out)
  end

  def find_fil
    @files = Dir.glob("#{dir}/*.{#{EXT}}").select { |f| File.file? f }
    @files += Dir.glob("#{dir}/*").select { |f| File.directory? f } unless mp3?
    @files.sort_by!(&:naturalized)
    @files.sort_by!(&:swapcase)
  end

  def validate
    validate_files
    validate_val(aud, :aud)
    validate_val(sub, :sub)
    validate_val(tit, :tit)
    raise "Width of the table should exeeds 14 symbols: #{wid}." if wid < 15
  end

  def validate_files
    raise "#{dir} doesn't have #{EXT} files or directories." if @files.empty?

    bad = @files.reject { |f| File.readable?(f) }
    raise "Unable to read #{bad} files." unless bad.empty?

    return if @tit.nil?

    f = @files.dup
    (@tit.size - 1).times { @files += f }
  end

  def validate_val(val, tag)
    f = @files.size
    (@options[tag] = Array.new(f, '0')).nil? || return if val.nil?
    s = val.size
    if s == 1
      @options[tag] = Array.new(f, val.first)
    else
      return if tag == :tit
      raise "#{tag} and files do not suit #{s} != #{f}." unless s == f
    end
  end

  def act?
    @options[:act]
  end

  def sca?
    @options[:sca]
  end

  def mp3?
    @options[:mp3]
  end

  def dir
    @options[:dir]
  end

  def tit
    @options[:tit]
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

  def add(file, res, aud = 0, sub = 0, tit = 0)
    row = [Utils.trim(File.basename(file), @str)]
    if aud != 0 || sub != 0
      (row << [
        { value: aud, alignment: :right },
        { value: sub, alignment: :right },
        { value: tit, alignment: :right }
      ]).flatten!
    end
    @row << row
    @sta[res ? :converted : :failed] += 1
  end

  def head
    head = [{ value: 'file', alignment: :center }]
    if @row.first.size == 4
      (head << [
        { value: 'audio', alignment: :center },
        { value: 'subtitles', alignment: :center },
        { value: 'titles', alignment: :center }
      ]).flatten!
    end
    head
  end

  def table
    Terminal::Table.new(
      title: Utils.trim(@tit, @ttl),
      headings: head,
      rows: @row,
      style: { width: @tbl }
    )
  end

  def do
    msg = "#{@act ? 'Real' : 'Test'}:#{stat} in #{@tim.read}."
    msg = Utils.trim(msg, @ttl)
    puts "#{table}\n| #{msg}#{' ' * (@ttl - msg.length)} |\n+-#{'-' * @ttl}-+"
  end

  def stat
    out = ''
    @sta.each do |k, v|
      out += ' ' + v.to_s + ' ' + k.to_s + ',' if v.positive?
    end
    out.chop
  end
end

# Transcodes any video file to m4v format.
class Transcoder
  def initialize
    @cfg = Configuration.new
    @rep = Reporter.new(@cfg.act?, "#{@cfg.dir} -> #{@cfg.out}", @cfg.wid)
  end

  # Runs command and prints output instantly. Returns true on success.
  def run(cmd)
    cmd += ' 2>&1'
    puts "Run: #{cmd}."
    IO.popen(cmd).each do |line|
      puts line.chomp
    end.close
    $CHILD_STATUS.success?
  end

  def m4v_cmd(file, aud, sub, tit)
    c = 'transcode-video --m4v --no-log --preset veryslow'\
        " --output #{@cfg.out}"
    c += " --main-audio #{aud}" unless aud == '0'
    c += " --burn-subtitle #{sub}" unless sub == '0'
    c += " --title #{tit}" unless til == '0'
    c + " #{file.shellescape}"
  end

  # Converts files, audibale, subtitles and titles arrays to array:
  #   [ file1 [ aud1, sub1, tit1 ] ]
  #   [ file2 [ aud2, sub2, tit2 ] ]
  def data
    @data ||= @cfg.files.zip([@cfg.aud, @cfg.sub, @cfg.tit].transpose)
  end

  def m4v
    data.each do |f, as|
      res = @cfg.act? ? run(m4v_cmd(f, as[0], as[1], as[2])) : true
      @rep.add(f, res, as[0], as[1], as[2])
    end
  end

  def mp3_cmd(file)
    file = file.shellescape
    "ffmpeg -i #{file} -vn -ar 44100 -ac 2 -ab 192k -f mp3 "\
      "#{@cfg.out}/#{File.basename(file, '.*')}.mp3"
  end

  def scn_cmd(file)
    "transcode-video --scan #{file.shellescape}"
  end

  def do # rubocop:disable Metrics/AbcSize
    if @cfg.mp3?
      @cfg.files.each { |f| @rep.add(f, @cfg.act? ? run(mp3_cmd(f)) : true) }
    elsif @cfg.sca?
      @cfg.files.each { |f| @rep.add(f, run(scn_cmd(f))) }
    else
      m4v
    end
    @rep.do
  end
end

PidFile.new
Transcoder.new.do
