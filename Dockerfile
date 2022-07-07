# A container for high-quality deinterlacing of video files.
#
# docker build --no-cache -t simonhorlick/vapoursynth .
#
FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
  apt-get install -y build-essential autoconf automake autotools-dev libtool pkg-config curl git xz-utils

# zimg library
RUN git clone -b release-2.9.3 https://github.com/sekrit-twc/zimg.git /usr/src/zimg
RUN cd /usr/src/zimg && \
  ./autogen.sh && \
  ./configure && \
  make && \
  make install

# Cython for Python3. Vapoursynth requires Cython >= 0.28.
RUN apt-get install -y cython3

RUN git clone -b R51 https://github.com/vapoursynth/vapoursynth.git /usr/src/vapoursynth
RUN cd /usr/src/vapoursynth && \
  ./autogen.sh && \
  ./configure && \
  make && \
  make install

RUN apt-get install -y nasm yasm libtool pkg-config libfftw3-dev libpng-dev libsndfile1-dev libxvidcore-dev libbluray-dev zlib1g-dev libopencv-dev ocl-icd-libopencl1 opencl-headers libboost-filesystem-dev libboost-system-dev 

RUN git clone https://github.com/darealshinji/vapoursynth-plugins.git /usr/src/vapoursynth-plugins && \
  cd /usr/src/vapoursynth-plugins && \
  git checkout 614d367e826b5f6bb0af33e1f91453f3ff7999ec

# Do not attempt to build waifu2x-w2xc as it doesn't compile on ubuntu 20.04
RUN rm -rf /usr/src/vapoursynth-plugins/plugins/waifu2x-w2xc

RUN cd /usr/src/vapoursynth-plugins && \
  ./autogen.sh && \
  ./configure && \
  make && \
  make install

#RUN \
#  git clone https://github.com/simonhorlick/vsrawsource.git /usr/src/vsrawsource && \
#  cd /usr/src/vsrawsource && \
#  ./configure && \
#  make && \
#  mkdir -p /usr/local/lib/vapoursynth/ && \
#  cp libvsrawsource.so /usr/lib/x86_64-linux-gnu/vapoursynth/rawsource.so && \
#  rm -rf /usr/src/vsrawsource

RUN \
  mkdir -p $(python3 -m site --user-site) && \
  cd $(python3 -m site --user-site) && \
  curl -LO https://raw.githubusercontent.com/HomeOfVapourSynthEvolution/havsfunc/e56f8f787bd4b679e6d14c9b08bf0460a3480ea4/havsfunc.py && \
  curl -LO https://raw.githubusercontent.com/HomeOfVapourSynthEvolution/mvsfunc/67c098c999b31fe49fa04bb6c8e8ea43efab4cff/mvsfunc.py && \
  curl -LO https://raw.githubusercontent.com/dubhater/vapoursynth-adjust/737057778a7da02cf686d9aeaf667610cedd3907/adjust.py && \
  curl -LO https://raw.githubusercontent.com/mawen1250/VapourSynth-script/0983895c8a0fe65d8b342e1875294d2681c75e84/nnedi3_resample.py

RUN apt install -y ffmpeg
#RUN \
#  curl -O https://johnvansickle.com/ffmpeg/builds/ffmpeg-git-amd64-static.tar.xz && \
#  tar -xvf ffmpeg-git-amd64-static.tar.xz  && \
#  cp ffmpeg-git-*-amd64-static/ffmpeg /bin/ffmpeg && \
#  cp ffmpeg-git-*-amd64-static/ffprobe /bin/ffprobe

RUN apt install -y valgrind

COPY deinterlace.vpy /
COPY entrypoint.sh /

ENV PYTHONPATH /usr/local/lib/python3.8/site-packages

CMD [ "./entrypoint.sh" ]
