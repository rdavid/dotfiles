#!/usr/local/bin/zsh
if [[ $EUID -ne 0 ]]; then
echo "This script must be run as root."
  exit 1
fi

cp /etc/fstab-tmp /etc/fstab
mount -a
cp /etc/fstab-prm /etc/fstab

echo "Done!"
