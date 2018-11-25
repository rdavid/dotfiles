#!/usr/bin/env ruby
# vim: tabstop=2 shiftwidth=2 expandtab textwidth=80 linebreak wrap
#
# rename.rb
#
# Copyright 2018 David Rabkin
#
# This script renames files in given directory by specific rules.
require 'terminal-table'

row = []
st1 = '01234567890123456789012'
st2 = 'GPS_20180407_073828.log'
(0..3).each do |_|
  row << [st1, st2]
end

puts Terminal::Table.new(
  title: 'title',
  headings: [
    { value: 'src', alignment: :center },
    { value: 'dst', alignment: :center }
  ],
  rows: row,
  style: {width: 79}
  )
