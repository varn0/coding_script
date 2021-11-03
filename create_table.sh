#!/bin/bash

CODECS=(libx264 libx265 libvpx-vp9 libaom-av1)
CRF_1=(16 23 30 40)
CRF_2=(21 28 35 50)
VIDEOS_PATH=coded_videos

# TODO - Optimize data collection
get_data_from_logs() {
        frameI=$(sed -n 's/.*frame I:\(.*\)Avg.*/\1/p' ${VIDEOS_PATH}/video_"$1"_"$2")
        frameP=$(sed -n 's/.*frame P:\(.*\)Avg.*/\1/p' ${VIDEOS_PATH}/video_"$1"_"$2")
        frameB=$(sed -n 's/.*frame B:\(.*\)Avg.*/\1/p' ${VIDEOS_PATH}/video_"$1"_"$2")
        bitrate=$(mediainfo ${VIDEOS_PATH}/video_"$1"_"$2" | sed -n 's/Bit rate.*: \(.*\) kb\/s/\1/p')
        size=$(find ${VIDEOS_PATH}/video_"$1"_"$2" -printf "%s")
        computetime=$(sed -n 's/.*rtime=\(.*\)s/\1/p' ${VIDEOS_PATH}/video_"$1"_"$2")
        cpuload=$(paste -d " "  - - < ${VIDEOS_PATH}/mon_cpu_"$1"_"$2".log | awk -F ' ' '$1 {sum += $1} END {printf sum/NR}')
        maxmem=$(sed -n 's/.*maxrss=\(.*\)kB/\1/p' ${VIDEOS_PATH}/video_"$1"_"$2")
        ssim=$(ffmpeg -i ${VIDEOS_PATH}/video_"$1"_"$2".mkv -i reference_crf0_x264_3_yuv420.mkv -lavfi psnr="stats_file=psnr_$1_$2.log" -f null - 2>&1 | sed -n 's/.*average:\(.*\)min.*/\1/p')          
        psnr=$(ffmpeg -i ${VIDEOS_PATH}/video_"$1"_"$2".mkv -i reference_crf0_x264_3_yuv420.mkv -lavfi psnr="stats_file=psnr_$1_$2.log" -f null - 2>&1 | sed -n 's/.*average:\(.*\)min.*/\1/p')
}

for codec in "${CODECS[@]}"; do
    if [ "${codec:0:4}" == 'libx' ]; then
        for crf in "${CRF_1[@]}"; do
            get_data_from_logs "$codec" "$crf"
            echo "$frameI,$frameP,$frameB,$bitrate,$size,$computetime,$cpuload,$maxmem,$ssim,$psnr"
        done
    else
        for crf in "${CRF_2[@]}"; do
            get_data_from_logs "$codec" "$crf"
            echo "$frameI,$frameP,$frameB,$bitrate,$size,$computetime,$cpuload,$maxmem,$ssim,$psnr"
        done
    fi
done > codecs_info.csv

