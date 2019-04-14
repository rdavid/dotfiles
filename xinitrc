#!/bin/sh
# vim: tabstop=2 shiftwidth=2 expandtab textwidth=80 linebreak wrap
#
# xinitrc
#
# Copyright 2016-present David Rabkin

# Sets DPI if external monitor is connected.
if [ "$(xrandr --query | grep 'connected 1920x1200')" != "" ]; then
  echo "Xft.dpi: 100" | xrdb -merge
fi

exec i3
