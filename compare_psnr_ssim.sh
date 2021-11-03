#!/bin/bash

VIDEOS_PATH=coded_videos
VIDEOS=("$VIDEOS_PATH"/video_*)

for video in "${VIDEOS[@]}"
do
    echo "${video:19}"
    ffmpeg -i "$video" -i reference_crf0_x264_3_yuv420.mkv -lavfi  psnr="stats_file=psnr_$video.log"  -f null - > "$VIDEOS_PATH"/psnr_"${video:19}".log 2>&1 
    ffmpeg -i "$video" -i reference_crf0_x264_3_yuv420.mkv -lavfi  ssim="stats_file=ssim_$video.log"  -f null - > "$VIDEOS_PATH"/ssim_"${video:19}".log 2>&1
done