#!/bin/bash
set -euxo pipefail

inputfile=$1
outputfile=$2

filename=$(basename "$inputfile")
extension="${filename##*.}"
filename="${filename%.*}"
path=$(dirname "$inputfile")

logfile="${outputfile}.log"

echo "[$(date +"%F %R")] Starting deinterlace of $filename" >> "$logfile"

# Now we determine the audio-video offset by probing the original stream.
audioTrackStart=$(ffprobe -v error -select_streams a:0 -show_entries stream=start_time -of default=noprint_wrappers=1:nokey=1 "$inputfile" | head -1)
videoTrackStart=$(ffprobe -v error -select_streams v:0 -show_entries stream=start_time -of default=noprint_wrappers=1:nokey=1 "$inputfile" | head -1)
audioOffset=$(awk "BEGIN{ print $videoTrackStart-$audioTrackStart }")

echo "[$(date +"%F %R")] audioTrackStart = $audioTrackStart" >> "$logfile"
echo "[$(date +"%F %R")] videoTrackStart = $videoTrackStart" >> "$logfile"
echo "[$(date +"%F %R")] audioOffset = $audioOffset" >> "$logfile"

rawsource="${outputfile}.source.y4m"
mezzaninevideo="${outputfile}.mezzanine-video.mkv"

if [[ -f "$rawsource" ]]; then
  echo "$rawsource exists."
else
  # Decode the source video into raw yuv420p
  ffmpeg -nostats -y -i "$inputfile" -err_detect ignore_err -pix_fmt yuv420p -f yuv4mpegpipe "$rawsource" </dev/null
fi

# Decode the source video into raw yuv420p and pass to vapoursynth, then take
# the result and do a transparent encode into h.264.
ln -sv "$rawsource" /tmp/input.y4m
vspipe --progress --requests 1 --y4m /deinterlace.vpy - | ffmpeg \
  -nostats \
  -y \
  -i - \
  -c:v libx264 -crf 0 -preset ultrafast \
  "$mezzaninevideo"
rm "$rawsource"

echo "[$(date +"%F %R")] Muxing audio" >> "$logfile"

# Mux the original audio streams with the deinterlaced video stream.
ffmpeg \
  -nostats -y \
  -i "$inputfile" \
  -itsoffset "$audioOffset" \
  -i "${mezzaninevideo}" \
  -c copy \
  -map 0:a \
  -map 1:v:0 \
  -shortest \
  "${outputfile}" </dev/null
rm "${mezzaninevideo}"

echo "[$(date +"%F %R")] Finished" >> "$logfile"
