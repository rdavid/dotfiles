#!/bin/sh
# vim: tabstop=2 shiftwidth=2 expandtab textwidth=80 linebreak wrap
#
# xinitrc
#
# Copyright 2016-present David Rabkin

if [ "$(xrandr --query | grep 'connected')" != "" ]; then
  echo "Xft.dpi: 100" | xrdb -merge
  xrandr -s 1920x1080
fi

exec i3
