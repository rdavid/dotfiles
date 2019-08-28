#!/usr/bin/env ruby
# frozen_string_literal: true

# vim: tabstop=2 shiftwidth=2 expandtab textwidth=80 linebreak wrap
#
# Copyright 2018-present David Rabkin
#
# This script renames files in given directory by specific rules.

require 'fileutils'
require 'optparse'
require 'set'
require 'terminal-table'
require_relative 'utils'

# Handles input parameters.
class Configuration
  DIC = [
    ['-a', '--act',     'Real renaming.',              :act],
    ['-r', '--rec',     'Passes recursively.',         :rec],
    ['-l', '--lim',     'Limits name length.',         :lim],
    ['-m', '--mod',     'Prepends modification time.', :mod],
    ['-d', '--dir dir', 'Directory to rename.',        :dir],
    ['-s', '--src src', 'A string to substitute.',     :src],
    ['-t', '--dst dst', 'A string to replace to.',     :dst],
    ['-p', '--pre pre', 'A string to prepend to.',     :pre],
    ['-w', '--wid wid', 'Width of the table.',         :wid]
  ].freeze

  def initialize # rubocop:disable AbcSize
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

  def act?
    @options[:act]
  end

  def rec?
    @options[:rec]
  end

  def lim?
    @options[:lim]
  end

  def mod?
    @options[:mod]
  end

  def dir
    @options[:dir]
  end

  def src
    @options[:src]
  end

  def dst
    @options[:dst]
  end

  def pre
    @options[:pre]
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

# An interface for actions implementation.
class Action
  def do(src)
    raise "Undefined method Action.do is called with #{src}."
  end

  def set(src) end

  def p2m(src)
    src.tr('.', '-')
  end
end

# All names should be downcased.
class DowncaseAction < Action
  def do(src)
    src.downcase
  end
end

# All points besides extention are replaced by minus.
class PointAction < Action
  def initialize(dir)
    raise 'dir cannot be nil.' if dir.nil?

    @dir = dir
  end

  def do(src)
    if File.file?(File.join(@dir, src))
      p2m(File.basename(src, '.*')) << File.extname(src)
    else
      p2m(src)
    end
  end
end

# All special symbols besides some (., &, $) are replaced by minus.
class CharAction < Action
  SYM = ' (){},~\'![]_#@=„“”`—+‘’;·‡«»%…'.chars.to_set.freeze

  def do(src)
    src.chars.map { |s| SYM.include?(s) ? '-' : s }.join
  end
end

# Transliterate to English.
class ToEnAction < Action
  MSC = {
    'ё' => 'jo',
    'ж' => 'zh',
    'ц' => 'tz',
    'ч' => 'ch',
    'ш' => 'sh',
    'щ' => 'szh',
    'ю' => 'ju',
    'я' => 'ya',
    '$' => '-usd-',
    '№' => '-num-',
    '&' => '-and-'
  }.freeze
  SRC = 'абвгдезийклмнопрстуфхъыьэ¨áéĭöü'.chars.freeze
  DST = 'abvgdeziyklmnoprstufh y e aeiou'.chars.freeze
  DIC = SRC.zip(DST).to_h.merge(MSC).freeze

  def do(src)
    src.chars.map { |c| DIC[c].nil? ? c : DIC[c] }.collect(&:strip).join
  end
end

# Substitutes a string with a string.
class SubstituteAction < Action
  def initialize(src, dst)
    raise 'src cannot be nil.' if src.nil?

    # The action works after PointAction. All points are replaces with minus.
    @src = p2m(src)
    @dst = dst.nil? ? '-' : p2m(dst)
  end

  def do(src)
    src.gsub(@src, @dst)
  end
end

# Prepends user patter.
class PrependAction < Action
  def initialize(pat)
    raise 'pat cannot be nil.' if pat.nil?

    @pat = pat
  end

  def do(src)
    src.prepend(@pat)
  end
end

# Prepends file modification datestamp.
class PrependDateAction < Action
  def initialize(dir)
    @dir = dir
  end

  def do(src)
    src.prepend(File.mtime(File.join(@dir, @src)).strftime('%Y%m%d-'))
  end

  def set(src)
    @src = src
  end
end

# Replaces multiple minuses to single. Trims minuses.
class TrimAction < Action
  def do(src)
    src.gsub!(/-+/, '-')
    src.gsub!('-.', '.')
    src.gsub!('.-', '.')
    src.gsub!(/^-|-$/, '') unless src == '-'
    src
  end
end

# Limits file length.
class TruncateAction < Action
  def initialize(lim)
    raise 'lim cannot be nil.' if lim.nil?

    @lim = lim
  end

  def do(src)
    return src unless src.length > @lim

    ext = File.extname(src)
    len = ext.length
    dst = len >= @lim ? ext[0..@lim - 1] : src[0..@lim - 1 - len] << ext
    dst.gsub!(/-$/, '')
    dst.gsub!('-.', '.')
    dst
  end
end

# Adds number from 0 to 9 in case of file existence.
class ExistenceAction < Action
  ITERATION = 10

  def initialize(dir, lim)
    raise 'dir cannot be nil.' if dir.nil?
    raise 'lim cannot be nil.' if lim.nil?

    @dir = dir
    @lim = lim
  end

  def do(src) # rubocop:disable MethodLength, CyclomaticComplexity, AbcSize
    raise 'ExistenceAction needs original file name.' if @src.nil?
    return src if src == @src
    return src unless File.exist?(File.join(@dir, src))

    if src.length == @lim
      ext = File.extname(src)
      src = src[0..@lim - ext.length - ITERATION.to_s.length + 1]
      src << ext
    end
    nme = File.basename(src, '.*')
    nme = '' if nme.length == 1
    ext = File.extname(src)
    (0..ITERATION).each do |i|
      n = File.join(@dir, nme + i.to_s + ext)
      return n unless File.exist?(n)
    end
    raise "Unable to compose a new name: #{src}."
  end

  def set(src)
    @src = src
  end
end

# Omits file names shorter than limit.
class OmitAction < Action
  def initialize(lim)
    raise 'lim cannot be nil.' if lim.nil?

    @lim = lim
  end

  def do(src)
    src.length < @lim ? nil : src
  end
end

# Produces actions for certain directories.
class ActionsFactory
  LIMIT = 143 # Synology eCryptfs limitation.

  def initialize(cfg)
    @cfg = cfg
  end

  def produce(dir) # rubocop:disable MethodLength, AbcSize
    if @cfg.lim?
      [
        OmitAction.new(LIMIT),
        TruncateAction.new(LIMIT)
      ]
    else
      [
        PointAction.new(dir), # Should be the first.
        @cfg.src.nil? ? nil : SubstituteAction.new(@cfg.src, @cfg.dst),
        DowncaseAction.new,
        CharAction.new,
        ToEnAction.new,
        @cfg.mod? ? PrependDateAction.new(dir) : nil,
        @cfg.pre.nil? ? nil : PrependAction.new(@cfg.pre),
        TrimAction.new,
        TruncateAction.new(LIMIT),
        ExistenceAction.new(dir, LIMIT)
      ].compact
    end
  end
end

# Formats and prints output data.
class Reporter
  @@tim = Timer.new
  @@sta = { moved: 0, unaltered: 0, failed: 0 }

  def self.init(act, wid)
    @@act = act
    @@tbl = wid
    @@ttl = wid - 4
    @@str = (wid - 7) / 2
  end

  def initialize(dir)
    @dir = dir
    @row = []
  end

  def add(lhs, rhs)
    if rhs.is_a?(StandardError)
      tag = :failed
      rhs = "#{rhs.message} (#{rhs.class})"
    elsif rhs == ''
      tag = :unaltered
    else
      tag = :moved
    end
    @@sta[tag] += 1
    @row << [Utils.trim(lhs, @@str), Utils.trim(rhs, @@str)]
  end

  def do
    puts Terminal::Table.new(
      title: Utils.trim(@dir, @@ttl),
      headings: [
        { value: 'src', alignment: :center },
        { value: 'dst', alignment: :center }
      ],
      rows: @row,
      style: { width: @@tbl }
    )
  end

  def self.stat_out
    out = ''
    @@sta.each do |k, v|
      out += ' ' + v.to_s + ' ' + k.to_s + ',' if v.positive?
    end
    out.chop
  end

  def self.final
    msg = "#{@@act ? 'Real' : 'Test'}:#{stat_out} in #{@@tim.read}."
    msg = Utils.trim(msg, @@ttl)
    puts "| #{msg}#{' ' * (@@ttl - msg.length)} |\n+-#{'-' * @@ttl}-+"
  end
end

# Renames file by certain rules.
class Renamer
  def initialize
    @cfg = Configuration.new
    @fac = ActionsFactory.new(@cfg)
  end

  def move(dir, dat) # rubocop:disable MethodLength, AbcSize
    rep = Reporter.new(dir)
    dat.each do |src, dst|
      if src == dst
        rep.add(File.basename(src), '')
        next
      end
      begin
        FileUtils.mv(src, dst) if @cfg.act?
        rep.add(File.basename(src), File.basename(dst))
      rescue StandardError => e
        rep.add(File.basename(src), e)
        puts e.backtrace.join("\n\t")
              .sub("\n\t", ": #{e}#{e.class ? " (#{e.class})" : ''}\n\t")
      end
    end
    rep.do
  end

  def do_dir(dir) # rubocop:disable MethodLength, CyclomaticComplexity, AbcSize
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

  def do
    Reporter.init(@cfg.act?, @cfg.wid)
    do_dir(@cfg.dir)
    Reporter.final
  end
end

Renamer.new.do
