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

# Handles input parameters.
class Configuration
  def initialize
    ARGV << '-h' if ARGV.empty?
    @options = {}
    OptionParser.new do |opts|
      opts.banner = 'Usage: rename.rb [options].'
      opts.on('-d', '--dir dir',
              'Directory with files to rename.') { |o| @options[:dir] = o }
    end.parse!

    raise 'Directory option is not given' if @options[:dir].nil?
  end

  def dir
    @options[:dir]
  end
end

class Action
  def do(_)
    raise 'Undefined method Action.do is called.'
  end
  def name
    raise 'Undefined method Action.name is called.'
  end
end

class DowncaseAction < Action
  def do(src)
    src.downcase
  end
  def name
    'downcase'
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
    dst = ''
    src.each_char { |s| dst << (s == '.' ? '-' : s) }
    dst
  end
  def name
    'point'
  end
end

class CharAction < Action
  def initialize
    # All special characters without point (.) and and (&).
    @sym = ' (){},~\'![]_#@=“”`—’+;·‡«»$%'.chars
  end
  def do(src)
    dst = src.chars
    dst.map! { |s| s = (@sym.include?(s) ? '-' : s) }
    dst.join
  end
  def name
    'char'
  end
end

class StrAction < Action
  def initialize
    @pat = [
      { src: '&', dst: '-and-'},
      { src: '---', dst: '-' },
      { src: '--',  dst: '-' }
    ]
  end
  def do(src)
    @pat.each { |p| src.gsub!(p[:src], p[:dst]) }
    src
  end
  def name
    'str'
  end
end

class TrimAction < Action
  def do(src)
    src.gsub(/\A[-]+|[-]+\z/, '')
  end
  def name
    'trim'
  end
end

class Renamer
  def initialize
    @dir = Configuration.new.dir
    @act = [
      PointAction.new(@dir),
      DowncaseAction.new,
      CharAction.new,
      StrAction.new,
      TrimAction.new
    ]
  end

  def do
    str = ''
    @act.each { |a| str << a.name << ', ' }
    str = str[0..-3]
    puts("Renames files at #{@dir} with #{str}.\n")
    Dir["#{@dir}/*"].each { |f|
      t = File.basename(f)
      @act.each { |a| t = a.do(t) }
      n = "#{@dir}/#{t}"
      puts("mv #{File.basename(f)} to #{File.basename(n)}.")
    }
  end
end

Renamer.new.do
