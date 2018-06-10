#! /bin/bash

if [ "$(xrandr --query | grep 'connected 1920x1200')" != "" ]; then
  echo "Xft.dpi: 96" | xrdb -merge
fi

exec i3
