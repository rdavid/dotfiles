#!/usr/bin/env python

# TODO Add license header
from __future__ import print_function

from time import localtime
from sys import exc_info
from sys import exit

DEFAULT_RESOLUTION = 5
MIDDAY = 12

# TODO Internationalize
HOUR_WORD_MAPPINGS = {
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
    12: "noon"
}


# TODO Internationalize
MINUTE_WORD_MAPPINGS = {
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
    55: "five"
}


def _increment_hour(hour):
    # Handle wrapping around from 11 PM to 12 AM
    if (hour != 23):
        return hour + 1
    return 0


def _convert_hour_to_word(hour):
    normalized_hour = hour
    if hour > MIDDAY:
        normalized_hour = hour - MIDDAY
    return HOUR_WORD_MAPPINGS[normalized_hour]


def _convert_minute_to_word(minutes, resolution):
    nearest = minutes - (minutes % resolution)
    if nearest not in MINUTE_WORD_MAPPINGS:
        raise ValueError("Unable to convert {0} to a word.".format(minutes))
    return MINUTE_WORD_MAPPINGS[nearest]


def _is_half_past_hour(minutes, resolution):
    if minutes >= 30 + resolution:
        return True
    return False


def to_fuzzy_time(hour, minutes, resolution):
    normalized_hour = hour
    conjunction = "past"
    if _is_half_past_hour(minutes, resolution):
        normalized_hour = _increment_hour(hour)
        conjunction = "till"

    hour_word = _convert_hour_to_word(normalized_hour)
    minute_word = _convert_minute_to_word(minutes, resolution)
    if minute_word:
        return " ".join([minute_word, conjunction, hour_word])
    elif normalized_hour not in [0, 12]:
        return "{0} o'clock".format(hour_word)
    return hour_word


if __name__ == "__main__":
    time_to_convert = localtime()
    resolution = DEFAULT_RESOLUTION
    try:
        # TODO Add command line arguments for passing in time
        # TODO Add command line argument to override the locale
        # TODO Add command line argument to override the default resolution
        print(to_fuzzy_time(time_to_convert.tm_hour,
                            time_to_convert.tm_min,
                            resolution))
    except:
        print("Failed to convert {0} due to {1}".format(time_to_convert,
                                                        exc_info()))
        exit(1)
