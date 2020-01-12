# vim: tabstop=2 shiftwidth=2 expandtab textwidth=80 linebreak wrap
# frozen_string_literal: true

# Copyright 2018-present David Rabkin

# All methods are static.
class Utils
  class << self
    SEP = '~'
    def trim(src, lim)
      return src if src.length <= lim

      beg = fin = (lim - SEP.length) / 2
      beg -= 1 if lim.odd?
      src[0..beg] + SEP + src[-fin..-1]
    end
  end
end

# Returns string with humanized time interval.
class Timer
  DIC = [
    [60,   :seconds, :second],
    [60,   :minutes, :minute],
    [24,   :hours,   :hour],
    [1000, :days,    :day]
  ].freeze

  def initialize
    @sta = Time.now
  end

  def read
    humanize(Time.now - @sta)
  end

  def humanize(sec)
    return 'less than a second' if sec < 1

    DIC.map do |cnt, nms, nm1|
      next if sec <= 0

      sec, n = sec.divmod(cnt)
      "#{n.to_i} #{n.to_i != 1 ? nms : nm1}"
    end.compact.reverse.join(' ')
  end
end

# Adds natural sort method. This converts something like "Filename 10" into a
# simple array with floats in place of numbers [ "Filename", 10.0 ]. See:
#   https://stackoverflow.com/questions/4078906/is-there-a-natural-sort-by-method-for-ruby
class String
  def naturalized
    scan(/[^\d\.]+|[\d\.]+/).collect { |f| f.match(/\d+(\.\d+)?/) ? f.to_f : f }
  end
end
