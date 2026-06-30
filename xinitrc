# vi: lbr noet sw=2 ts=2 tw=79 wrap
# SPDX-FileCopyrightText: 2016-2026 David Rabkin
# SPDX-License-Identifier: 0BSD

if xrandr --query | grep -q 'DP-1-3 connected'; then
  xrandr --output DP-1-3 --auto --left-of eDP-1
fi
exec i3
