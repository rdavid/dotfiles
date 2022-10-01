#!/bin/sh
# vi:ts=2 sw=2 tw=79 et lbr wrap
# Copyright 2021 David Rabkin

IMG="$HOME/dotfiles/pic/bg.jpg"
TMP='/tmp/screen.png'
[ -f "$TMP" ] || convert "$IMG" "$TMP"
i3lock -t -i "$TMP"
