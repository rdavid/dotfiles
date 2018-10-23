#!/usr/bin/env bash
# transcode.sh

# Calculates duration time for report.
duration()
{
  dur=`expr $(date +%s) - $1`
  printf "%d:%02d:%02d" \
         `expr $dur / 3600` \
         `expr $dur % 3600 / 60` \
         `expr $dur % 60`
}

if [ 0 -eq $# ]; then
  echo "transcode.sh <file name>"
  exit 0
fi

if [ $1 = "scan" ]; then
  transcode-video --scan $2
  exit 0
fi

declare -a AUD=( $(for i in {1..88}; do echo 3; done) )
declare -a SUB=( $(for i in {1..88}; do echo 2; done) )
declare -a FIL=( "$@" )

if [ ${#AUD[@]} -ne ${#SUB[@]} ]; then
  echo "Audio and subtitles arrays don't have same size."
  exit 1
fi

if [ ${#AUD[@]} -ne ${#FIL[@]} ]; then
  echo "Audio ${#AUD[@]} and files ${#FIL[@]} arrays don't have same size."
  exit 1
fi

echo "Following jobs will be processed:"
for (( i=0; i < ${#FIL[@]}; i++ ))
do
  echo "$(($i+1)): ${FIL[$i]}: ${AUD[$i]}: ${SUB[$i]}" 
done

read -r -p "Are you sure? [y/N] " response
case "$response" in
  [yY][eE][sS]|[yY])
    # Continues.
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
                  --output /home/david/ ${FIL[$i]}

  #transcode-video --no-log \
  #                --m4v \
  #                --main-audio ${AUD[$i]} \
  #                --preset veryslow \
  #                --output /home/david/ ${FIL[$i]}

  #transcode-video --no-log \
  #                --m4v \
  #                --preset veryslow \
  #                --output /home/david/ ${FIL[$i]}

  #transcode-video --title 3 \
  #                --no-log \
  #                --m4v \
  #                --main-audio $AUD \
  #                --preset veryslow \
  #                --output /home/david/ "$file"

  #transcode-video --no-log --m4v --main-audio $AUD --add-srt "${file}.srt" --preset veryslow --output /home/david/ "$file"
done

cp /home/david/*.m4v /home/david/ds-box/ibx/
rm /home/david/*.m4v

echo "Done in `duration $BEG`."
