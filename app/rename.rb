#!/usr/bin/env ruby
# vim: tabstop=2 shiftwidth=2 expandtab textwidth=80 linebreak wrap
#
# make.rb
#
# Copyright 2018 David Rabkin
#
# This script renames files in given directory by specific rules.
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
    end.parse!

    raise 'Directory option is not given' if @options[:dir].nil?
  end
  def dir
    @options[:dir]
  end
  def act?
    @options[:act]
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
      replace(File.basename(src, ".*")) << File.extname(src)
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
    @sym = ' (){},~\'![]_#@=“”`—’+;·‡«»$%'.chars
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
      ё: 'jo',
      ж: 'zh',
      ц: 'tz',
      ч: 'ch',
      ш: 'sh',
      щ: 'szh',
      ю: 'ju',
      я: 'ya'
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
    src.gsub!('&', '-and-')
    puts src
    src.gsub!('----', '-')
    puts src
    src.gsub!('---', '-')
    puts src
    src.gsub!('--', '-')
    puts src
    src.gsub!(/\A[-]+|[-]+\z/, '')
    puts src
    src
  end
end

class Renamer
  def initialize
    @cfg = Configuration.new
    @act = [
      PointAction.new(@cfg.dir),
      DowncaseAction.new,
      CharAction.new,
      RuToEnAction.new,
      TrimAction.new
    ]
  end

  def do
    row = []
    Dir["#{@cfg.dir}/*"].each { |src|
      t = File.basename(src)
      @act.each { |a| t = a.do(t) }
      dst = "#{@cfg.dir}/#{t}"
      FileUtils.mv(src, dst) if @cfg.act?
      row << [File.basename(src), File.basename(dst)]
    }
    puts Terminal::Table.new(
      title: (@cfg.act? ? 'real' : 'simulation') << ': ' << @cfg.dir,
      headings: ['source', 'destination'],
      rows: row
    )
  end
end

Renamer.new.do
