# vi:ts=2 sw=2 tw=79 et lbr wrap
# Copyright 2016 by David Rabkin

if [ "$(xrandr --query | grep 'connected')" != "" ]; then
  echo "Xft.dpi: 100" | xrdb -merge
  xrandr -s 1920x1080
fi

exec i3
