#!/usr/bin/env python3
# vi: et lbr sw=2 ts=2 tw=79 wrap
# SPDX-FileCopyrightText: 2019-2026 David Rabkin
# SPDX-License-Identifier: 0BSD
"""Prints the current time in fuzzy words for the i3blocks widget."""

import sys
from time import localtime

RESOLUTION = 5
MIDDAY = 12

HOURS = {
  0: "midnight",
  1: "one",
  2: "two",
  3: "three",
  4: "four",
  5: "five",
  6: "six",
  7: "seven",
  8: "eight",
  9: "nine",
  10: "ten",
  11: "eleven",
  12: "noon",
}

MINUTES = {
  0: "",
  5: "five",
  10: "ten",
  15: "quarter",
  20: "twenty",
  25: "twenty-five",
  30: "half",
  35: "twenty-five",
  40: "twenty",
  45: "quarter",
  50: "ten",
  55: "five",
}


def _hour_word(hour):
  return HOURS[hour - MIDDAY if hour > MIDDAY else hour]


def _minute_word(minutes):
  nearest = minutes - minutes % RESOLUTION
  if nearest not in MINUTES:
    raise ValueError(f"Unable to convert {minutes} to a word.")
  return MINUTES[nearest]


def _next_hour(hour):
  return 0 if hour == 23 else hour + 1


def to_fuzzy_time(hour, minutes):
  """Converts the time to words like ten past nine or quarter to noon."""
  word = "past"
  if minutes >= 30 + RESOLUTION:
    hour = _next_hour(hour)
    word = "to"
  hrw = _hour_word(hour)
  mnw = _minute_word(minutes)
  if mnw:
    return f"{mnw} {word} {hrw}"
  if hour not in (0, 12):
    return f"{hrw} o'clock"
  return hrw


if __name__ == "__main__":
  now = localtime()
  try:
    print(to_fuzzy_time(now.tm_hour, now.tm_min))
  except ValueError as err:
    print(f"Failed to convert {now}: {err}")
    sys.exit(1)
