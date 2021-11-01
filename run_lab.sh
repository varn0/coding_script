#!/bin/bash

CODECS=(libaom-av1)
# CODECS=(libx264 libx265 libvpx-vp9 libaom-av1)
CRF_1=(16 23 30 40)
CRF_2=(21 28 35 50)

monitor () {
    
}

code () {
    ffmpeg -framerate 24 -i sintel-480p/sintel_trailer_2k_%04d.png -benchmark -c:v "$1" -crf "$2" -pix_fmt yuv420p coded_videos/"$1"_"$2".mkv > coded_videos/coding_"$1"_"$2".log 2>&1 &
    pss=$!
    while kill -0 $pss 2> /dev/null; do
        top -n 1 | awk -F ',' 'FNR==1{print $3}' | awk -F ':' '{print $2}' >> coded_videos/mon_cpu_"${codec}"_"${crf}".log
        sleep 5
    done
    echo "Coding duration was:"
    sed -n 's/.* rtime=\(.*\)/\1/p' coded_videos/coding_"$1"_"$2".log
}

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
            ffmpeg -framerate 24 -i sintel-480p/sintel_trailer_2k_%04d.png -benchmark -c:v "$codec" -crf "$crf" -pix_fmt yuv420p -strict -2 -cpu-used 4 coded_videos/coding_"$codec"_"$crf".mkv > coded_videos/coding_"$codec"_"$crf".log 2>&1 &
            pss=$!
            echo "este es el pid $pss"
            while kill -0 $pss 2> /dev/null; do
                echo "entro al monitor code"
                top -n 1 | awk -F ',' 'FNR==1{print $3}' | awk -F ':' '{print $2}' >> coded_videos/mon_cpu_"$codec"_"$crf".log
                sleep 5
            done
        done
    fi
    done
