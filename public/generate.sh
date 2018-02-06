#!/usr/bin/env bash

# media related config
INPUT_FILE="tudresden"
GOPSIZE=180
QUALITIES=(25 30 40 50)

# exec related config
BENTO_BIN_DIR="/Users/alexanderb/Downloads/Bento4-SDK-1-4-2-594.universal-apple-macosx/bin/Release"
BENTO_SCRIPT_DIR="/devel/git/mmk_dash/Bento4/Source/Python/utils"

# clean up previous run
rm $INPUT_FILE-*
rm -r output

# generate mp4 files with closed GOPs in different qualities
for quality in ${QUALITIES[@]};
do
  ffmpeg -i $INPUT_FILE.mp4 -c:v libx264 -x264opts keyint=$GOPSIZE:min-keyint=$GOPSIZE:scenecut=-1 -crf $quality $INPUT_FILE-$quality.mp4
done

# verify that keyframes are in the beginning of each chunk
for quality in ${QUALITIES[@]};
do
  ./verify.sh $GOPSIZE $INPUT_FILE-$quality.mp4
done

# fragment mp4 files
for quality in ${QUALITIES[@]};
do
  $BENTO_BIN_DIR/mp4fragment --fragment-duration 6 $INPUT_FILE-$quality.mp4 $INPUT_FILE-$quality-fragmented.mp4
done

# call mp4-dash.py
MEDIA_SOURCES=""
for quality in ${QUALITIES[@]};
do
  MEDIA_SOURCES="$MEDIA_SOURCES $INPUT_FILE-$quality-fragmented.mp4"
done
$BENTO_SCRIPT_DIR/mp4-dash.py --exec-dir $BENTO_BIN_DIR $MEDIA_SOURCES