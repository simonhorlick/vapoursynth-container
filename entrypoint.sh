#!/bin/bash
set -v

inputfile=$1

filename=$(basename "$inputfile")
extension="${filename##*.}"
filename="${filename%.*}"
path=$(dirname "$inputfile")

logfile="${path}/${filename}-qtgmc-mezzanine.log"

echo "[$(date +"%F %R")] Starting deinterlace of $filename" >> "$logfile"

# Now we determine the audio-video offset by probing the original stream.
audioTrackStart=$(ffprobe -v error -select_streams a:0 -show_entries stream=start_time -of default=noprint_wrappers=1:nokey=1 "$inputfile" | head -1)
videoTrackStart=$(ffprobe -v error -select_streams v:0 -show_entries stream=start_time -of default=noprint_wrappers=1:nokey=1 "$inputfile" | head -1)
audioOffset=$(awk "BEGIN{ print $videoTrackStart-$audioTrackStart }")

echo "[$(date +"%F %R")] Input file $filename contains $frames frames" >> "$logfile"
echo "[$(date +"%F %R")] audioTrackStart = $audioTrackStart" >> "$logfile"
echo "[$(date +"%F %R")] videoTrackStart = $videoTrackStart" >> "$logfile"
echo "[$(date +"%F %R")] audioOffset = $audioOffset" >> "$logfile"

# Decode the source video into raw yuv420p
ffmpeg -nostats -y -i "$inputfile" -err_detect ignore_err -pix_fmt yuv420p -f yuv4mpegpipe "${path}/${filename}.y4m"

# Symlink the source to a well known location (this is used in the vapoursynth script).
ln -sv "${path}/${filename}.y4m" /tmp/input.y4m

# Pass the raw source video into vapoursynth for processing then do a quick,
# high-quality encode into H.264.
vspipe --progress --requests 1 --y4m /deinterlace.vpy - | ffmpeg \
  -nostats \
  -y \
  -i - \
  -c:v libx264 -crf 5 \
  "${path}/${filename}-qtgmc-mezzanine-video.mkv" 2>> "$logfile"

echo "[$(date +"%F %R")] Muxing audio" >> "$logfile"

# Mux the original audio streams with the deinterlaced video stream.
ffmpeg \
  -nostats -y \
  -i "$inputfile" \
  -itsoffset "$audioOffset" \
  -i "${path}/${filename}-qtgmc-mezzanine-video.mkv" \
  -c copy \
  -map 0:a \
  -map 1:v:0 \
  -shortest \
  "${path}/${filename}-qtgmc-mezzanine.mkv"

# Remove temporary file.
rm "${path}/${filename}-qtgmc-mezzanine-video.mkv"

echo "[$(date +"%F %R")] Finished" >> "$logfile"
