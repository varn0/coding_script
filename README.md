# Testing codecs laboratory
This repository contains a bash script to automate the encoding of a video file using several codecs and compression rate factors (CRFs) formats.

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

This is the command to obtain the reference video from a set of images

```bash
ffmpeg -i <source_images> ...
```

