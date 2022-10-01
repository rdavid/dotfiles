#!/usr/bin/env ruby
# frozen_string_literal: true

# vi:ts=2 sw=2 tw=79 et lbr wrap
# Copyright 2018-2022 David Rabkin
#
# This script prints a country name by public IP.

require 'English'
require 'json'
require 'rubygems'

# Runs curl silently with 1 second time out.
str = `curl -s -m 1 ipinfo.io`
if !$CHILD_STATUS.success? || str.include?('timed out')
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
