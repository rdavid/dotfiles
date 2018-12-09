#!/usr/bin/env ruby
# vim: tabstop=2 shiftwidth=2 expandtab textwidth=80 linebreak wrap
#
# rename.rb
#
# Copyright 2018 David Rabkin
#
# This script renames files in given directory by specific rules.
require 'set'
require 'colorize'
require 'optparse'
require 'fileutils'
require 'terminal-table'

# Handles input parameters.
class Configuration
  def initialize
    ARGV << '-h' if ARGV.empty?
    @options = {}
    OptionParser.new do |opts|
      opts.banner = 'Usage: rename.rb [options].'
      opts.on('-d', '--dir dir',
              'Directory with files to rename.') { |o| @options[:dir] = o }
      opts.on('-s', '--src src',
              'A string to substitute from a name.') { |o| @options[:src] = o }
      opts.on('-t', '--dst dst',
              'A string to replace with in a name.') { |o| @options[:dst] = o }
      opts.on('-a', '--act',
              'Real renaming.') { |o| @options[:act] = o }
      opts.on('-r', '--rec',
              'Passes directories recursively.') { |o| @options[:rec] = o }
      opts.on('-l', '--lim',
              'Limits file name length to eCryptfs.') { |o| @options[:lim] = o }
      opts.on('-w', '--wid wid',
              'Width of the table presentation.') { |o| @options[:wid] = o }
    end.parse!

    raise 'Directory option is not given.' if @options[:dir].nil?
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
    @options[:wid]
  end
end

# An interface for actions implementation.
class Action
  def act(src)
    raise "Undefined method Action.do is called with #{src}."
  end
end

# All names should be downcased.
class DowncaseAction < Action
  def act(src)
    src.downcase
  end
end

# All points besides extention are replaced by minus.
class PointAction < Action
  def initialize(dir)
    @dir = dir
  end

  def act(src)
    if File.file?(File.join(@dir, src))
      replace(File.basename(src, '.*')) << File.extname(src)
    else
      replace(src)
    end
  end

  def replace(src)
    src.tr('.', '-')
  end
end

# All special symbols are replaced by minus.
class CharAction < Action
  def initialize
    # All special characters without 'point' (.) and 'and' (&).
    @sym = ' (){},~\'![]_#@=“„”`—’+;·‡«»$%…'.chars.to_set
  end

  def act(src)
    dst = src.chars
    dst.map! { |s| @sym.include?(s) ? '-' : s }
    dst.join
  end
end

# Transliterate from Cyrillic to English.
class RuToEnAction < Action
  def initialize
    mu = {
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
    }
    ru = 'абвгдезийклмнопрстуфхъыьэ'.chars
    en = 'abvgdeziyklmnoprstufh y e'.chars
    @dic = ru.zip(en).to_h.merge(mu)
  end

  def act(src)
    dst = ''
    src.each_char do |c|
      d = @dic[c]
      case d
      when nil
        dst << c
      when ' '
        next
      else
        dst << d
      end
    end
    dst
  end
end

# Replaces user patter with minus.
class SubstituteAction < Action
  def initialize(src, dst)
    # The action works after PointAction. All points are replaces with minus.
    @src = src
    @src.tr!('.', '-') unless @src.nil?
    @dst = dst.nil? ? '-' : dst.tr('.', '-')
  end

  def act(src)
    src.gsub!(@src, @dst) unless @src.nil?
    src
  end
end

# Replaces multiple minuses to single. Trims minuses.
class TrimAction < Action
  def act(src)
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
    @lim = lim
  end

  def act(src)
    return src unless src.length > @lim

    ext = File.extname(src)
    src =
      if ext.length >= @lim
        ext[0..@lim - 1]
      else
        src[0..@lim - 1 - ext.length] << ext
      end
    src.gsub!(/-$/, '')
    src.gsub!('-.', '.')
    src
  end
end

# Adds number from 0 to 9 in case of file existence.
class ExistenceAction < Action
  ITERATION = 10
  def initialize(dir, lim)
    @dir = dir
    @lim = lim
  end

  def act(src)
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
end

# Omits file names shorter than limit.
class OmitAction < Action
  def initialize(lim)
    @lim = lim
  end

  def act(src)
    src.length < @lim ? nil : src
  end
end

# Renames file by certain rules.
class Renamer
  PTH_LIMIT = 4096
  NME_LIMIT = 143 # Synology eCryptfs limitation.

  def initialize
    @cfg = Configuration.new
    @sta = { moved: 0, unaltered: 0 }
    @tbl = @cfg.wid.nil? ? 79 : @cfg.wid.to_i
    @ttl = @tbl - 4
    @str = (@tbl - 7) / 2
  end

  def trim(src, lim)
    return src if src.length <= lim

    beg = fin = (lim - 2) / 2
    beg -= 1 if lim.even?
    src[0..beg] + '..' + src[-fin..-1]
  end

  def do_dir(dir)
    raise "No such directory: #{dir}." unless File.directory?(dir)

    act =
      if @cfg.lim?
        [
          OmitAction.new(NME_LIMIT),
          TruncateAction.new(NME_LIMIT)
        ]
      else
        [
          PointAction.new(dir), # Should be the first.
          SubstituteAction.new(@cfg.src, @cfg.dst),
          DowncaseAction.new,
          CharAction.new,
          RuToEnAction.new,
          TrimAction.new,
          TruncateAction.new(NME_LIMIT)
        ]
      end
    row = []
    exi = ExistenceAction.new(dir, NME_LIMIT)
    Dir.foreach(dir) do |src|
      next if ['.', '..'].include?(src)

      src = File.join(dir, src)
      do_dir(src) if @cfg.rec? && File.directory?(src)
      nme = File.basename(src)
      act.each do |i|
        nme = i.act(nme)
        break if nme.nil?
      end
      next if nme.nil?

      dst = File.join(dir, nme)
      if dst != src
        nme = exi.act(nme)
        dst = File.join(dir, nme)
        raise "Path exceeds #{PTH_LIMIT}: #{dst}." if dst.length > PTH_LIMIT

        FileUtils.mv(src, dst) if @cfg.act?
        @sta[:moved] += 1
      else
        @sta[:unaltered] += 1
      end
      row << [
        trim(File.basename(src), @str),
        trim(File.basename(dst), @str)
      ]
    end
    return unless row.any?

    puts Terminal::Table.new(
      title: trim(dir, @ttl),
      headings: [
        { value: 'src', alignment: :center },
        { value: 'dst', alignment: :center }
      ],
      rows: row,
      style: { width: @tbl }
    )
  end

  def do
    do_dir(@cfg.dir)
    puts "#{@cfg.act? ? 'Real' : 'Simulation'}"\
         " moved #{@sta[:moved]}, unaltered #{@sta[:unaltered]}."
  end
end

Renamer.new.do
