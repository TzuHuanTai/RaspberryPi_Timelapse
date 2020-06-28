#!/bin/bash
# Information:
# 	Set the rtmp/hls config at 
#	/etc/nginx/modules-enabled/rtmp.conf
#	/etc/nginx/nginx.conf

gst-launch-1.0 -v v4l2src device=/dev/video0 ! 'video/x-raw, width=1280, height=720, framerate=30/1' ! queue ! videoconvert ! omxh264enc ! h264parse ! flvmux ! rtmpsink location='rtmp://localhost:1935/hls/test'

# return 0 to system
exit 0