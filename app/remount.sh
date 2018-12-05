#!/usr/local/bin/zsh
# vim: tabstop=2 shiftwidth=2 expandtab textwidth=80 linebreak wrap
#
# remount.sh
#
# Copyright 2016-2018 David Rabkin

if [[ $EUID -ne 0 ]]; then
echo "This script must be run as root."
  exit 1
fi

cp /etc/fstab-tmp /etc/fstab
mount -a
cp /etc/fstab-prm /etc/fstab

echo "Done!"
