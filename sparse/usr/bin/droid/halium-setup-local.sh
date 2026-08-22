#! /bin/sh

mkdir -p /data/vendor/audiohal/audio_param/
chmod a+w /data/vendor/audiohal/audio_param

#Late load the swpm modules
modprobe mtk-swpm
modprobe mtk-swpm-dbg-common-v1
modprobe mtk-swpm-dbg-v6789
