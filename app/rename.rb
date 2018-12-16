#!/usr/bin/env ruby
# vim: tabstop=2 shiftwidth=2 expandtab textwidth=80 linebreak wrap
#
# rename.rb
#
# Copyright 2018 David Rabkin
#
# This script renames files in given directory by specific rules.
#

require 'set'
require 'colorize'
require 'optparse'
require 'fileutils'
require 'terminal-table'

# Handles input parameters.
class Configuration
  DIC = [
    ['-a', '--act',     'Real renaming.',          :act],
    ['-r', '--rec',     'Passes recursively.',     :rec],
    ['-l', '--lim',     'Limits name length.',     :lim],
    ['-d', '--dir dir', 'Directory to rename.',    :dir],
    ['-s', '--src src', 'A string to substitute.', :src],
    ['-t', '--dst dst', 'A string to replace to.', :dst],
    ['-p', '--pre pre', 'A string to prepend to.', :pre],
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

  def act?
    @options[:act]
  end

  def rec?
    @options[:rec]
  end

  def lim?
    @options[:lim]
  end

  def wid
    @options[:wid].nil? ? 79 : @options[:wid].to_i
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

# All special symbols besides 'point' (.) and 'and' (&) are replaced by minus.
class CharAction < Action
  SYM = ' (){},~\'![]_#@=“„”`—’+;·‡«»$%…'.chars.to_set.freeze

  def do(src)
    src.chars.map { |s| SYM.include?(s) ? '-' : s }.join
  end
end

# Transliterate from Cyrillic to English.
class RuToEnAction < Action
  MSC = {
    'ё' => 'jo',
    'ж' => 'zh',
    'ц' => 'tz',
    'ч' => 'ch',
    'ш' => 'sh',
    'щ' => 'szh',
    'ю' => 'ju',
    'я' => 'ya',
    '№' => '-num-',
    '&' => '-and-'
  }.freeze
  RUS = 'абвгдезийклмнопрстуфхъыьэ'.chars.freeze
  ENG = 'abvgdeziyklmnoprstufh y e'.chars.freeze
  DIC = RUS.zip(ENG).to_h.merge(MSC).freeze

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

  def do(src)
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

  def produce(dir)
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
        RuToEnAction.new,
        @cfg.pre.nil? ? nil : PrependAction.new(@cfg.pre),
        TrimAction.new,
        TruncateAction.new(LIMIT),
        ExistenceAction.new(dir, LIMIT)
      ].compact
    end
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
        "#{n.to_i} #{n.to_i != 1 ? nms : nm1}"
      end.compact.reverse.join(' ')
    end
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
    @sta = { moved: 0, unaltered: 0, failed: 0 }
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

  def do
    sta = Time.now
    do_dir(@cfg.dir)
    puts "#{@cfg.act? ? 'Real' : 'Simulation'}:"\
         " #{@sta[:moved]} moved,"\
         " #{@sta[:unaltered]} unaltered,"\
         " #{@sta[:failed]} failed in "\
         "#{Utils.humanize(Time.now - sta)}."
  end
end

Renamer.new.do
