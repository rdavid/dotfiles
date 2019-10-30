#!/bin/sh
youtube-dl \
  --playlist-reverse \
  --download-archive /media/data/app/box/youtube/done.txt \
  -i -o \
  "/media/data/app/box/done/%(uploader)s/%(playlist)s-s01e%(playlist_index)s-%(title)s-[%(id)s].%(ext)s" \
  -f bestvideo[ext=mp4]+bestaudio[ext=m4a] \
  --merge-output-format mp4 \
  --add-metadata \
  --write-thumbnail \
  --batch-file=/media/data/app/box/youtube/channels.txt
