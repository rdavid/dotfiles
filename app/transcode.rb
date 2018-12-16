#!/usr/bin/env ruby
# vim: tabstop=2 shiftwidth=2 expandtab textwidth=80 linebreak wrap
#
# transcode.rb
#
# Copyright 2018 David Rabkin
#
# Transcodes any video file to m4v format.
#

require 'set'
require 'colorize'
require 'optparse'
require 'fileutils'
require 'terminal-table'

# Handles input parameters.
class Configuration
  DIC = [
    ['-a', '--act',     'Real encoding.',          :act],
    ['-c', '--sca',     'Scan first file.',        :sca],
    ['-d', '--dir dir', 'Directory to transcode.', :dir],
    ['-u', '--aud aud', 'Audio stream number.',    :aud],
    ['-s', '--sub sub', 'Subtitle stream number.', :sub],
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
    @options[:wid].nil? ? 79 : @options[:wid].to_i
  end
end

# All methods ara static.
class Utils
  DIC = [
    [60,   :seconds, :second],
    [60,   :minutes, :minute],
    [24,   :hours,   :hour],
    [1000, :days,    :day]
  ].freeze

  class << self
    def trim(src, lim)
      return src if src.length <= lim

      beg = fin = (lim - 2) / 2
      beg -= 1 if lim.even?
      src[0..beg] + '..' + src[-fin..-1]
    end

    def humanize(sec)
      DIC.map do |cnt, nms, nm1|
        next if sec <= 0

        sec, n = sec.divmod(cnt)
        "#{n.to_i} #{n != 1 ? nms : nm1}"
      end.compact.reverse.join(' ')
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

  def add(rhs)
    @row << [Utils.trim(rhs, @str)]
  end

  def do
    puts Terminal::Table.new(
      title: Utils.trim(@tit, @ttl),
      headings: [
        { value: 'file', alignment: :center }
      ],
      rows: @row,
      style: { width: @tbl }
    )
  end
end

# Transcodes any video file to m4v format.
class Transcoder
  EXT = %i[avi mkv].map(&:to_s).join(',').freeze

  def initialize
    @cfg = Configuration.new
    @sta = { converted: 0, failed: 0 }
    @rep = Reporter.new(@cfg.dir, @cfg.wid)
  end

  def do
    sta = Time.now
    Dir[@cfg.dir + "/*.{#{EXT}}"].sort.each do |nme|
      @rep.add(nme)
      if @cfg.sca?
        v = `transcode-video --scan #{nme}`
        break
      end
    end
    @rep.do
    puts "#{@cfg.act? ? 'Real' : 'Simulation'}:"\
         " #{@sta[:converted]} converted,"\
         " #{@sta[:failed]} failed in "\
         "#{Utils.humanize(Time.now - sta)}."
  end
end

Transcoder.new.do
