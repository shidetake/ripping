#!/bin/sh

target_title_num=01

usage_exit()
{
  echo "Usage: $0 [-b] [-c] [-d] [-i input] [-o output]" 1>&2
  echo "  opt: -b: blu-ray" 1>&2
  echo "       -c: chapterize" 1>&2
  echo "       -d: dryrun" 1>&2
  echo "       -e: x265, x264 (default: x265)" 1>&2
  echo "       -i: input filename (default: /dev/disk3)" 1>&2
  echo "       -o: output filename (default: input.mp4)" 1>&2
  echo "       -t: target title num (default: 1)" 1>&2
  exit 1
}

if [ $# = 0 ]; then
  usage_exit
fi

while getopts 'bcdhi:o:t:' OPT ; do
case $OPT in
  b)
    b_bluray=1
    ;;
  c)
    b_split=1
    ;;
  d)
    b_dry_run=1
    ;;
  i)
    input=$OPTARG
    fext=${input##*.}
    output=$(dirname $input)/$(basename $input .$fext)
    ;;
  o)
    input=${input:=/dev/disk3}
    output=$OPTARG
    ;;
  t)
    target_title_num=$(printf "%02d" $OPTARG)
    echo $target_title_num
    ;;
  h)
    usage_exit
    ;;
  \?)
    usage_exit
    ;;
esac
done

if [ -z "$input" ]; then
  echo 'must set input or output'
  exit 0
fi

if [ -z "$output" ]; then
  echo 'must set input or output'
  exit 0
fi

if [ "$b_bluray" ]; then
  makemkvcon mkv dev:/dev/disk3 all ./
  exit 0
fi

opt="-t $target_title_num -Z 'H.265 MKV 1080p30' --all-audio -s '1,2,3,4,5,6' --crop 0:0:0:0 "

if [ $b_split ]; then
  if [ $b_dry_run ]; then
    lsdvd $input
  fi

  if [ ${input##*.} = "mkv" ]; then
    chapter_num=`ffmpeg -i $input 2>&1 | grep Chapter | tail -n 1 | awk '{print $4}'`
  else
    chapter_num=`lsdvd $input | grep Title:\ $target_title_num.*Chapter | awk '{gsub(/,/,""); print $6}'`
  fi
  for ((i = 1; i <= 10#$chapter_num; i++)); do
    cmd="HandBrakeCLI -c $i "$opt" -i "$input" -o "$output"_$(printf %02d $i).mkv"
    if [ $b_dry_run ]; then
      echo $cmd
    else
      eval $cmd
    fi
  done
else
  cmd="HandBrakeCLI "$opt" -i "$input" -o "$output".mkv"
  if [ $b_dry_run ]; then
    echo $cmd
  else
    eval $cmd
  fi
fi
