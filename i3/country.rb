#!/usr/bin/env ruby
# frozen_string_literal: true

# vi:ts=2 sw=2 tw=79 et lbr wrap
# Copyright 2018-2026 David Rabkin
#
# This script prints a country symbol based on the public IP.

require 'English'
require 'json'
require 'rubygems'

# Runs curl silently with a 1-second timeout.
str = `curl -s -m 1 ipinfo.io`
if !$CHILD_STATUS.success? || str.include?('timed out')
  print 'no'
  exit
end

# Extracts the country code.
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
