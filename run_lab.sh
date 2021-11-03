#!/bin/bash

CODECS=(libx264 libx265 libvpx-vp9 libaom-av1)
CRF_1=(16 23 30 40)
CRF_2=(21 28 35 50)
SOURCE=sintel-480p/sintel_trailer_2k_%04d.png
VIDEOS_PATH=coded_videos

monitor () {
    while kill -0 "$1" 2> /dev/null; do
        top -n 1 | awk -F ',' 'FNR==1{print $3}' | awk -F ':' '{print $2}' >> "$VIDEOS_PATH"/mon_"$2"_"$3".log
        top -n 1 | awk -F ',' 'FNR==4{print $3}' | awk -F ' ' '{print $2}' >> "$VIDEOS_PATH"/mon_"$2"_"$3".log
        sleep 5
    done
}

code () {
    ffmpeg -framerate 24 -i "$SOURCE" -benchmark -c:v "$1" -crf "$2" -pix_fmt yuv420p "$VIDEOS_PATH"/video_"$1"_"$2".mkv > "$VIDEOS_PATH"/coding_"$1"_"$2".log 2>&1 &
    pss=$!
    monitor $pss "$1" "$2"
    echo "Coding duration was:"
    sed -n 's/.* rtime=\(.*\)/\1/p' "$VIDEOS_PATH"/coding_"$1"_"$2".log
}

# Inital conditions, load average and MiB Mem used
top -n 1 | awk -F ',' 'FNR==1{print $3}' | awk -F ':' '{print $2}' >> "$VIDEOS_PATH"/initial_conditions.log
top -n 1 | awk -F ',' 'FNR==4{print $3}' | awk -F ' ' '{print $2}' >> "$VIDEOS_PATH"/initial_conditions.log
 

for codec in "${CODECS[@]}"; do
    if [ "${codec:0:4}" == 'libx' ]; then
        for crf in "${CRF_1[@]}"
        do
            echo "Coding with codec $codec and CRF $crf"
            code "$codec" "$crf"
        done
    elif [ "${codec:0:4}" == 'libv' ]; then
        for crf in "${CRF_2[@]}"
        do
            echo "Coding with codec $codec and CRF $crf"
            code "$codec" "$crf"
        done
    else
        for crf in "${CRF_2[@]}"
        do
            echo "Coding with codec $codec and CRF $crf"
            ffmpeg -framerate 24 -i sintel-480p/sintel_trailer_2k_%04d.png -benchmark -c:v "$codec" -crf "$crf" -pix_fmt yuv420p -strict -2 -cpu-used 4 "$VIDEOS_PATH"/video_"$codec"_"$crf".mkv > "$VIDEOS_PATH"/coding_"$codec"_"$crf".log 2>&1 &
            pss=$!
            monitor $pss "$codec" "$crf"
        done
    fi
    done

# Compare PSNR
VIDEOS=("$VIDEOS_PATH"/video_*)

for video in "${VIDEOS[@]}"
do
    echo "${video:19}"
    ffmpeg -i "$video" -i reference_crf0_x264_3_yuv420.mkv -lavfi  psnr="stats_file=psnr_$video.log"  -f null - > "$VIDEOS_PATH"/psnr_"${video:19}".log 2>&1 
    ffmpeg -i "$video" -i reference_crf0_x264_3_yuv420.mkv -lavfi  ssim="stats_file=ssim_$video.log"  -f null - > "$VIDEOS_PATH"/ssim_"${video:19}".log 2>&1
done


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


# Generate RATE and PSNR Table
ROWS=${#CRF_1[@]}
data=()

for ((i=1;i<=ROWS;i++)) do
    for codec in "${CODECS[@]}"; do
        if [ "${codec:0:4}" == 'libx' ]; then
            rate=$(mediainfo ${VIDEOS_PATH}/video_"${codec}"_"${CRF_1[(i-1)]}".mkv | sed -n 's/Bit rate.*: \(.*\) kb\/s/\1/p')
            psnr=$(ffmpeg -i ${VIDEOS_PATH}/video_"${codec}"_"${CRF_1[(i-1)]}".mkv -i reference_crf0_x264_3_yuv420.mkv -lavfi psnr="stats_file=psnr_${codec}_${CRF_1[(i-1)]}.log" -f null - 2>&1 | sed -n 's/.*average:\(.*\)min.*/\1/p')
            data=("${data[@]}" "${rate},${psnr}")
        else
            rate2=$(mediainfo coded_videos/video_"${codec}"_"${CRF_2[(i-1)]}".mkv | sed -n 's/Bit rate.*: \(.*\) kb\/s/\1/p')
            psnr2=$(ffmpeg -i coded_videos/video_"${codec}"_"${CRF_2[(i-1)]}".mkv -i reference_crf0_x264_3_yuv420.mkv -lavfi psnr="stats_file=psnr_${codec}_${CRF_1[(i-1)]}.log" -f null - 2>&1 | sed -n 's/.*average:\(.*\)min.*/\1/p')
            data=("${data[@]}" "${rate2},${psnr2}")
        fi
    done
    echo "${data[0]},${data[1]},${data[2]},${data[3]}"
    data=()
done > bitrate_psnr_info.log