# vim: tabstop=2 shiftwidth=2 expandtab textwidth=80 linebreak wrap
#
# utils.rb
#
# Copyright 2018 David Rabkin
#

# All methods ara static.
class Utils
  class << self
    def trim(src, lim)
      return src if src.length <= lim

      beg = fin = (lim - 2) / 2
      beg -= 1 if lim.even?
      src[0..beg] + '..' + src[-fin..-1]
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
    DIC.map do |cnt, nms, nm1|
      next if sec <= 0

      sec, n = sec.divmod(cnt)
      "#{n.to_i} #{n.to_i != 1 ? nms : nm1}"
    end.compact.reverse.join(' ')
  end
end
