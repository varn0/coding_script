#!/bin/bash

CODECS=(libx264 libx265 libvpx-vp9 libaom-av1)
CRF_1=(16 23 30 40)
CRF_2=(21 28 35 50)
VIDEOS_PATH=coded_videos
RERUN_QM=false


# TODO - Optimize data collection
get_data_from_logs() {
        frameI=$((crf++))
        frameP=$((crf++))
        frameB=$((crf++))
        bitrate=$((crf++))
        # size=$((crf++))
        # computetime=$((crf++))
        # cpuload=$((crf++))
        # maxmem=$((crf++))
        ssim=$((crf++))
        # psnr=$((crf++))
        # if [ "${1:0:4}" == 'libx' ]; then
        #     # TODO sanitize data
        #     frameI=$(sed -n 's/.*frame I:\(.*\)Avg.*/\1/p' ${VIDEOS_PATH}/coding_"$1"_"$2".log)
        #     frameP=$(sed -n 's/.*frame P:\(.*\)Avg.*/\1/p' ${VIDEOS_PATH}/coding_"$1"_"$2".log)
        #     frameB=$(sed -n 's/.*frame B:\(.*\)Avg.*/\1/p' ${VIDEOS_PATH}/coding_"$1"_"$2".log)
        # elif [ "${1:0:4}" == 'libv' ]; then
        #     frameI=$(ffprobe  -v error -show_frames ${VIDEOS_PATH}/video_"$1"_"$2".mkv | grep pict_type=I | wc -l)
        #     frameP=$(ffprobe  -v error -show_frames ${VIDEOS_PATH}/video_"$1"_"$2".mkv | grep pict_type=P | wc -l)
        #     frameB=$(ffprobe  -v error -show_frames ${VIDEOS_PATH}/video_"$1"_"$2".mkv | grep pict_type=B | wc -l)
        # else
        #     frameI="0"
        #     frameP="0"
        #     frameB="0"
        # fi
        # bitrate=$(mediainfo ${VIDEOS_PATH}/video_"$1"_"$2".mkv | sed -n 's/Bit rate.*: \(.*\) kb\/s/\1/p')
        size=$(find ${VIDEOS_PATH}/video_"$1"_"$2".mkv -printf "%s")
        computetime=$(sed -n 's/.*rtime=\(.*\)s/\1/p' ${VIDEOS_PATH}/coding_"$1"_"$2".log)
        cpuload=$(paste -d " "  - - < ${VIDEOS_PATH}/mon_"$1"_"$2".log | awk -F ' ' '$1 {sum += $1} END {printf sum/NR}')
        maxmem=$(sed -n 's/.*maxrss=\(.*\)kB/\1/p' ${VIDEOS_PATH}/coding_"$1"_"$2".log)
        if [ ! -f data/psnr_stdout_"$1"_"$2".log ] || [ $RERUN_QM ]; then
            ffmpeg -i ${VIDEOS_PATH}/video_"$1"_"$2".mkv -i reference_crf0_x264_3_yuv420.mkv -lavfi psnr="stats_file=data/psnr_$1_$2.log" -f null - > data/psnr_stdout_"$1"_"$2".log 2>&1
            ffmpeg -i ${VIDEOS_PATH}/video_"$1"_"$2".mkv -i reference_crf0_x264_3_yuv420.mkv -lavfi ssim="stats_file=data/ssim_$1_$2.log" -f null - > data/ssim_stdout_"$1"_"$2".log 2>&1
        fi
        psnr=$(sed -n 's/.*average:\(.*\)min.*/\1/p' data/psnr_stdout_"$1"_"$2".log)
        ssim=$(sed -n 's/.*All:\(.*\)(.*/\1/p' data/ssim_stdout_"$1"_"$2".log)
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


