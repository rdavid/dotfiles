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

class Renamer
  def initialize
    @dir = Configuration.new.dir?
  end

  def do
    files = Dir["#{@dir}/*"]
    puts("Renames files at #{@dir}: #{files}.")
  end
end

Renamer.new.do
