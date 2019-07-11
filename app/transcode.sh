#!/bin/sh
#
# Copyright 2016-present David Rabkin

declare -a AUD=( $(for i in {1..13}; do echo 7; done) )
declare -a SUB=( $(for i in {1..13}; do echo 3; done) )
#declare -a AUD=( 1 1 1 )
#declare -a SUB=( 7 1 1 )
declare -a FIL=( "$@" )

# Calculates duration time for report.
duration()
{
  dur=`expr $(date +%s) - $1`
  printf '%d:%02d:%02d' \
         `expr $dur / 3600` \
         `expr $dur % 3600 / 60` \
         `expr $dur % 60`
}

if [ 0 -eq $# ]; then
  echo 'transcode.sh <file name>'
  exit 0
fi
if [ "$1" = 'scan' ]; then
  transcode-video --scan $2
  exit 0
fi
if [ ${#AUD[@]} -ne ${#SUB[@]} ]; then
  echo 'Audio and subtitles do not have the same size.'
  exit 1
fi
if [ ${#AUD[@]} -ne ${#FIL[@]} ]; then
  echo "Audio ${#AUD[@]} and files ${#FIL[@]} do not have the same size."
  exit 1
fi
echo 'Following jobs will be processed:'
for (( i=0; i < ${#FIL[@]}; i++ ))
do
  echo "$(($i+1)): ${FIL[$i]}: ${AUD[$i]}: ${SUB[$i]}" 
done
read -r -p 'Are you sure? [y/N] ' response
case "$response" in
  [yY][eE][sS]|[yY])
    ;;
  *)
    exit 0
    ;;
esac
BEG="$(date +%s)"
for (( i=0; i < ${#FIL[@]}; i++ ))
do
  transcode-video --no-log \
                  --m4v \
                  --main-audio ${AUD[$i]} \
                  --burn-subtitle ${SUB[$i]} \
                  --preset veryslow \
                  --output ~ ${FIL[$i]}

#  transcode-video --no-log \
#                  --m4v \
#                  --encoder x264_10bit \
#                  --main-audio ${AUD[$i]} \
#                  --burn-subtitle ${SUB[$i]} \
#                  --preset veryslow \
#                  --output ~ ${FIL[$i]}

#  transcode-video --no-log \
#                  --m4v \
#                  --main-audio ${AUD[$i]} \
#                  --preset veryslow \
#                  --output ~ ${FIL[$i]}

#  transcode-video --no-log \
#                  --m4v \
#                  --preset veryslow \
#                  --output ~ ${FIL[$i]}
  mv ~/*.m4v /mnt/nas-box/box/ibx
  echo "${FIL[$i]} done."
done
echo "Done in `duration $BEG`."
