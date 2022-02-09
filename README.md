# Testing codecs laboratory

This repository contains the script [run_lab.sh](run_lab.sh) to automate the encoding of a video file using several codecs and compression rate factors (CRFs) formats.

## What does the script do

- encodes a reference video using several codecs and CRFs
- obtains a set of data from the encoded videos
- process the data to be represented in different charts for further analysis

## Inputs of the script

- a reference video

## Outputs of the script

- encoded videos
- video data in csv format

## How to obtain the reference video

This command can be used to obtain the reference video from a set of images

```bash
ffmpeg -i img%03d.png -c:v libx264 -vf fps=25 -pix_fmt yuv420p out.mp4
```

