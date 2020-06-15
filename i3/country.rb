#!/usr/bin/env ruby
# vi:ts=2 sw=2 tw=79 et lbr wrap
# Copyright 2018 David Rabkin
#
# This script prints a country name by public IP.

require 'rubygems'
require 'json'

# Runs curl silently with 1 second time out.
str = `curl -s -m 1 ipinfo.io`
if !$?.success? || str.include?('timed out')
  print 'no'
  exit
end

# Extracts country name.
val = JSON.parse(str)['country'].downcase

case val
when 'us'
  val = ''
when 'il'
  val = ''
when 'ge', 'fr'
  val = ''
when 'uk'
  val = ''
when 'ru'
  val = ''
end

print val
