#!/usr/bin/env ruby
# frozen_string_literal: true

# vi:ts=2 sw=2 tw=79 et lbr wrap
# SPDX-FileCopyrightText: 2018-2026 David Rabkin
# SPDX-License-Identifier: 0BSD
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
begin
  val = JSON.parse(str).fetch('country').downcase
rescue JSON::ParserError, KeyError, NoMethodError
  print 'no'
  exit
end

case val
when 'us'
  val = ''
when 'il'
  val = ''
when 'ge', 'fr'
  val = ''
when 'gb', 'uk'
  val = ''
when 'ru'
  val = ''
end
print val
