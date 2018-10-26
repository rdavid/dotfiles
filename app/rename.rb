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

  def dir?
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

class DummyAction < Action
  def do(src)
    src
  end
  def name
    'dummy'
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

class ReplacePointAction < Action
  def do(src)
    dst = ''
    File.basename(src, ".*").each_char { |s| dst << (s == '.' ? '-' : s) }
    dst << File.extname(src)
    dst
  end
  def name
    'replace-point'
  end
end

class ReplaceAction < Action
  def do(src)
    dst = ''
    sym = ' (){}.,~\'![]_#@=“”`—’+;·‡&«»$'.chars
    sym += ['---', '--']
    src.each_char { |s| dst << (sym.include?(s) ? '-' : s) }
    dst
  end
  def name
    'replace'
  end
end

class AndAction < Action
  def do(src)
    src.gsub('-&-', '-and-')
  end
  def name
    'and'
  end
end

class TrimAction < Action
  def do(src)
    #Something like src.gsub('-', '')
    src
  end
  def name
    'and'
  end
end

class Renamer
  def initialize
    @dir = Configuration.new.dir?
    @act = [
      DummyAction.new,
      DowncaseAction.new,
      ReplacePointAction.new
      ReplaceAction.new,
      AndAction.new,
      TrimAction.new
    ]
  end

  def do
    str = ''
    @act.each { |a| str << a.name << ', ' }
    str = str[0..-3]
    puts("Renames files at #{@dir} with #{str}.")
    Dir["#{@dir}/*"].each { |f|
      t = File.basename(f)
      @act.each { |a| t = a.do(t) }
      n = "#{File.dirname(f)}/#{t}"
      puts("Renames #{f} to #{n}.")
    }
  end
end

Renamer.new.do
