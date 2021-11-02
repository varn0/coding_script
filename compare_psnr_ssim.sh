#!/bin/bash

VIDEOS_PATH=coded_videos
VIDEOS=("$VIDEOS_PATH"/video_*)

for video in "${VIDEOS[@]}"
do
    echo "$video"
    ffmpeg -i "$video" -i reference_crf0_x264_3_yuv420.mkv -lavfi  psnr="stats_file=psnr_$video.log"  -f null -
    ffmpeg -i "$video" -i reference_crf0_x264_3_yuv420.mkv -lavfi  ssim="stats_file=ssim_$video.log"  -f null -
done