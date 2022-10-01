# vi:ts=2 sw=2 tw=79 et lbr wrap
# Copyright 2016-2022 David Rabkin

if xrandr --query | grep -q 'DP-1-3 connected'; then
  xrandr --output DP-1-3 --auto --left-of eDP-1
fi
exec i3
