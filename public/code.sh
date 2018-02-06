#!/usr/bin/env bash
# 240p           426x240     400k 600k
# 360p           640x360     700k 900k
# 480p           854x480     1250k 1600k
# HD 720p        1280x720    2500k 3200k
# Full HD 1080p  1920x1080  4500k 5300k
#
# libvpx-vp9

FILE_INPUT="media/_sample.mp4"
DIR="vp9/dash+live"
SIZE="hd1080"

# Creo carpeta de segmentos
mkdir -p ${DIR}

<<COM
# HLS
ffmpeg \
    -i ${FILE_INPUT} \
    -c:v h264 \
    -s ${SIZE} \
    -hls_time 4 \
    -hls_playlist_type vod \
    -hls_segment_filename "${DIR}/segment_${SIZE}_%d.ts" \
    ${DIR}/playlist_${SIZE}.m3u8

COM

# DASH
<<COM
ffmpeg \
    -re -i ${FILE_INPUT} \
    -map 0 -map 0 \
    -c:a libfdk_aac \
    -c:v libvpx-vp9 \
    -b:v:0 800k -b:v:1 300k -s:v:1 320x170 -profile:v:1 baseline \
    -profile:v:0 main -bf 1 -keyint_min 120 -g 120 -sc_threshold 0 \
    -b_strategy 0 -ar:a:1 22050 -use_timeline 1 -use_template 1 \
    -window_size 5 -adaptation_sets "id=0,streams=v id=1,streams=a" \
    -f dash ${DIR}/playlist_${SIZE}.mpd

COM

# DASH + VP9 + VOD
<<COM
ffmpeg -i ${FILE_INPUT} -vn -acodec libvorbis -ab 128k -dash 1 ${DIR}/my_audio.webm

ffmpeg -i ${FILE_INPUT} -c:v libvpx-vp9 -keyint_min 150 \
-g 150 -tile-columns 4 -frame-parallel 1  -f webm -dash 1 \
-an -vf scale=160:190 -b:v 250k -dash 1 ${DIR}/video_160x90_250k.webm \
-an -vf scale=320:180 -b:v 500k -dash 1 ${DIR}/video_320x180_500k.webm \
-an -vf scale=640:360 -b:v 750k -dash 1 ${DIR}/video_640x360_750k.webm \
-an -vf scale=640:360 -b:v 1000k -dash 1 ${DIR}/video_640x360_1000k.webm \
-an -vf scale=1280:720 -b:v 1500k -dash 1 ${DIR}/video_1280x720_1500k.webm

ffmpeg \
  -f webm_dash_manifest -i ${DIR}/video_160x90_250k.webm \
  -f webm_dash_manifest -i ${DIR}/video_320x180_500k.webm \
  -f webm_dash_manifest -i ${DIR}/video_640x360_750k.webm \
  -f webm_dash_manifest -i ${DIR}/my_audio.webm \
  -c copy \
  -map 0 -map 1 -map 2 -map 3 \
  -f webm_dash_manifest \
  -adaptation_sets "id=0,streams=0,1,2 id=1,streams=3" \
  ${DIR}/my_video_manifest.mpd
COM

VP9_LIVE_PARAMS="-speed 6 -tile-columns 4 -frame-parallel 1 -threads 8 -static-thresh 0 -max-intra-rate 300 -deadline realtime -lag-in-frames 0 -error-resilient 1"



ffmpeg \
  -f webm_dash_manifest -live 1 \
  -i ${FILE_INPUT} \
  -f webm_dash_manifest -live 1 \
  -i ${FILE_INPUT} \
  -c copy \
  -map 0 -map 1 \
  -f webm_dash_manifest -live 1 \
    -adaptation_sets "id=0,streams=0 id=1,streams=1" \
    -chunk_start_index 1 \
    -chunk_duration_ms 2000 \
    -time_shift_buffer_depth 7200 \
    -minimum_update_period 7200 \
  ${DIR}/live_manifest.mpd