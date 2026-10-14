#!/usr/bin/env python3
# vi: et lbr sw=2 ts=2 tw=79 wrap
# SPDX-FileCopyrightText: 2019-2026 David Rabkin
# SPDX-License-Identifier: 0BSD
"""Prints the current day of the month for the i3blocks widget."""

from datetime import datetime

if __name__ == "__main__":
  print(datetime.now().strftime("%d "))
