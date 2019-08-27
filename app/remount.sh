#!/bin/sh
# vim: tabstop=2 shiftwidth=2 expandtab textwidth=80 linebreak wrap
#
# Copyright 2016-present David Rabkin

TMP='/etc/fstab-tmp'
PRM='/etc/fstab-prm'
if [ "$(id -u)" -ne '0' ] ; then
  echo "This script must be executed with root privileges."
  exit 1
fi
if [ ! -f "$TMP" ]; then
  echo "$TMP not found."
  exit 1
fi
if [ ! -f "$PRM" ]; then
  echo "$PRM not found."
  exit 1
fi
cp "$TMP" /etc/fstab && mount -a
cp "$PRM" /etc/fstab
echo 'Done!'
