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
      opts.on('-a', '--action',
              'Real renaming.') { |o| @options[:act] = o }
      opts.on('-r', '--recursive',
              'Passes directories recursively.') { |o| @options[:rec] = o }
      opts.on('-l', '--limit',
              'Limits file name length to eCryptfs.') { |o| @options[:lim] = o }
    end.parse!

    raise 'Directory option is not given.' if @options[:dir].nil?
    raise "No such directory: #{dir}." unless File.directory?(dir)
  end
  def dir
    @options[:dir]
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
end

class Action
  def do(_)
    raise 'Undefined method Action.do is called.'
  end
end

class DowncaseAction < Action
  def do(src)
    src.downcase
  end
end

class PointAction < Action
  def initialize(dir)
    @dir = dir
  end
  def do(src)
    if File.file?(File.join(@dir, src))
      replace(File.basename(src, '.*')) << File.extname(src)
    else
      replace(src)
    end
  end
  def replace(src)
    dst = src.chars
    dst.map! { |s| s == '.' ? '-' : s }
    dst.join
  end
end

class CharAction < Action
  def initialize
    # All special characters without point (.) and and (&).
    @sym = ' (){},~\'![]_#@=“”`—’+;·‡«»$%…'.chars.to_set
  end
  def do(src)
    dst = src.chars
    dst.map! { |s| @sym.include?(s) ? '-' : s }
    dst.join
  end
end

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
      '&' => '-and-'
    }
    ru = 'абвгдезийклмнопрстуфхъыьэ'.chars
    en = 'abvgdeziyklmnoprstufh y e'.chars
    @dic = ru.zip(en).to_h.merge(mu)
  end
  def do(src)
    dst = ''
    src.each_char { |c|
      d = @dic[c]
      case d
      when nil
        dst << c
      when ' '
        # no action
      else
        dst << d
      end
    }
    dst
  end
end

class TrimAction < Action
  def do(src)
    src.gsub!(/-+/, '-')
    src.gsub!(/^-|-$/, '')
    src.gsub!('-.', '.')
    src.gsub!('.-', '.')
    src
  end
end

class TruncateAction < Action
  def initialize(lim)
    @lim = lim
  end
  def do(src)
    return src unless src.length > @lim
    ext = File.extname(src)
    if (ext.length >= @lim)
      src = ext[0..@lim - 1]
    else
      src = src[0..@lim - 1 - ext.length] << ext
    end
    src.gsub!(/-$/, '')
    src.gsub!('-.', '.')
    src
  end
end

class ExistenceAction < Action
  ITERATION = 10
  def initialize(dir, lim)
    @dir = dir
    @lim = lim
  end
  def do(src)
    return src unless File.exist?(File.join(@dir, src))
    if (src.length == @lim)
      ext = File.extname(src)
      src = src[0..@lim - ext.length - ITERATION.to_s.length + 1]
      src << ext
    end
    nme = File.basename(src, '.*')
    nme = '' if (nme.length == 1)
    ext = File.extname(src)
    0..ITERATION.times do |i|
      n = File.join(@dir, "#{nme}#{i}#{ext}")
      return n unless File.exist?(n)
    end
    raise "Unable to compose a new name: #{src}."
  end
end

class OmitAction < Action
  def initialize(lim)
    @lim = lim
  end
  def do(src)
    return nil if src.length > @lim
    src
  end
end

class Renamer
  TBL_WIDTH = 79
  STR_WIDTH = (TBL_WIDTH - 9) / 2
  PTH_LIMIT = 4096
  NME_LIMIT = 143 # Synology eCryptfs limitation.
  #NME_LIMIT = 10 # Synology eCryptfs limitation.
  def initialize
    @cfg = Configuration.new
    @sta = { moved: 0, unaltered: 0 }
  end
  def do_dir(dir)
    raise "No such directory: #{dir}." unless File.directory?(dir)
    unless @cfg.lim?
      act = [
        PointAction.new(dir),
        DowncaseAction.new,
        CharAction.new,
        RuToEnAction.new,
        TrimAction.new,
        TruncateAction.new(NME_LIMIT)
      ]
    else
      act = [
        OmitAction.new(NME_LIMIT),
        TruncateAction.new(NME_LIMIT)
      ]
    end
    row = []
    exi = ExistenceAction.new(dir, NME_LIMIT)
    Dir.foreach(dir) { |src|
      next if (src == '.' || src == '..')
      src = File.join(dir, src)
      do_dir(src) if @cfg.rec? && File.directory?(src)
      t = File.basename(src)
      act.each { |a|
        t = a.do(t)
        break if t.nil?
      }
      next if t.nil?
      dst = File.join(dir, t)
      if (dst != src)
        t = exi.do(t)
        dst = File.join(dir, t)
        raise "File path exceeds #{PTH_LIMIT}: #{dst}." if dst.length > PTH_LIMIT
        FileUtils.mv(src, dst) if @cfg.act?
        @sta[:moved] += 1
      else
        @sta[:unaltered] += 1
      end
      row << [
        File.basename(src)[0..STR_WIDTH],
        File.basename(dst)[0..STR_WIDTH]
      ]
    }
    puts Terminal::Table.new(
      title: dir,
      headings: [
        { value: 'src', alignment: :center },
        { value: 'dst', alignment: :center }
      ],
      rows: row,
      style: {width: TBL_WIDTH}
    ) if row.any?
  end
  def do
    do_dir(@cfg.dir)
    puts "#{@cfg.act? ? 'Real' : 'Simulation'}"\
         " moved #{@sta[:moved]}, unaltered #{@sta[:unaltered]}."
  end
end

Renamer.new.do
