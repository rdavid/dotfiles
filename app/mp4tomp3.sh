#!/usr/local/bin/zsh

#for f in *.m4v
for f in *.mp4
#for f in *.avi
do
  echo $f
  #name=`echo "$f" | sed -e "s/.m4v$//g"`
  name=`echo "$f" | sed -e "s/.mp4$//g"`
  #name=`echo "$f" | sed -e "s/.avi$//g"`
  ffmpeg -i "$f" -vn -ar 44100 -ac 2 -ab 192k -f mp3 "$name.mp3"
done
