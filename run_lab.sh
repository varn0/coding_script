#!/bin/bash

CODECS=(libx264 libx265 libvpx-vp9 libaom-av1)
CRF_1=(16 23 30 40)
CRF_2=(21 28 35 50)

monitor () {
    while kill -0 "$1" 2> /dev/null; do
        top -n 1 | awk -F ',' 'FNR==1{print $3}' | awk -F ':' '{print $2}' >> coded_videos/mon_"$2"_"$3".log
        top -n 1 | awk -F ',' 'FNR==4{print $3}' | awk -F ' ' '{print $2}' >> coded_videos/mon_"$2"_"$3".log
        sleep 5
    done
}

code () {
    ffmpeg -framerate 24 -i sintel-480p/sintel_trailer_2k_%04d.png -benchmark -c:v "$1" -crf "$2" -pix_fmt yuv420p coded_videos/video_"$1"_"$2".mkv > coded_videos/coding_"$1"_"$2".log 2>&1 &
    pss=$!
    monitor $pss "$1" "$2"
    echo "Coding duration was:"
    sed -n 's/.* rtime=\(.*\)/\1/p' coded_videos/coding_"$1"_"$2".log
}

# Inital conditions, load average and MiB Mem used
top -n 1 | awk -F ',' 'FNR==1{print $3}' | awk -F ':' '{print $2}' >> coded_videos/initial_conditions.log
top -n 1 | awk -F ',' 'FNR==4{print $3}' | awk -F ' ' '{print $2}' >> coded_videos/initial_conditions.log
 

for codec in "${CODECS[@]}"
    do
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
            ffmpeg -framerate 24 -i sintel-480p/sintel_trailer_2k_%04d.png -benchmark -c:v "$codec" -crf "$crf" -pix_fmt yuv420p -strict -2 -cpu-used 4 coded_videos/video_"$codec"_"$crf".mkv > coded_videos/coding_"$codec"_"$crf".log 2>&1 &
            pss=$!
            monitor $pss "$codec" "$crf"
        done
    fi
    done
