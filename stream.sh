#!/bin/bash
if [ $# != 1 ] ; then
  echo "Parameter error"
  echo "Usage : $0 you | you1 | you2 | aka | akamai | ustream"
  exit
fi

if [[ -z "$AUTH_KEY" ]]; then
  echo "AUTH_KEY is not set"
  exit 1
fi

################### YouTube Settings ###################
# These data are available to you when you create a Live event in YouTube
# First Camera - INSERT YOUR OWN DATA
youtube_auth1=$AUTH_KEY
# Second Camera - Optional
youtube_auth2=''
youtube_app='live2'
serverurl='rtmp://a.rtmp.youtube.com/live2'$youtube_app
################### UStream Settings ###################
# RTMP URL from your UStream Account : See www.ustream.tv -> Channel -> Remote
rtmpurl='INSERT_YOUR_USTREAM_RTMP_URL_HERE'
# This is your Stream Key : See www.ustream.tv -> Channel -> Remote
streamkey='INSERT_YOUR_STREAM_KEY_HERE'
################### Twitch Settings ###################
twitch_server=live.twitch.tv
twitch_streamkey='INSERT_YOUR_STREAM_KEY_HERE'
# twitch_streamkey=live_12345678_6asdk3khhewrkhqe4k32AswlH6hrwd
################### Akamai Settings ###################
akamai_server='INSERT_YOUR_AKAMAI_SERVER_NAME_HERE'
akamai_user='INSERT_YOUR_AKAMAI_USER_NAME_HERE'
akamai_pass='INSERT_YOUR_AKAMAI_PASSWORD_NAME_HERE'
########################################################
# You can change the settings below to suit your needs
###################### Settings ########################
width=1280
height=720
audiorate=44100
channels=2
framerate='30/1'
vbitrate=4000
abitrate=320000
GST_DEBUG="--gst-debug=flvmux:4,rtmpsink:4"
# GST_DEBUG="--gst-debug=1"
###################### Settings ########################
########################################################
# THe following settings should not be changed
h264_level=4.1
h264_profile=main
h264_bframes=0
keyint=`echo "2 * $framerate" |bc`
datarate=`echo "$vbitrate + $abitrate / 1000" |bc`
flashver='FME/3.0%20(compatible;%20FMSc%201.0)'
akamai_flashver="flashver=FMLE/3.0(compatible;FMSc/1.0) playpath=I4Ckpath_12@44448"
########################################################

# This will detect gstreamer-1.0 over gstreamer-0.10
gstlaunch=`which gst-launch-1.0`
if [ X$gstlaunch != X ] ; then
  VIDEOCONVERT=videoconvert
  VIDEO='video/x-raw, format=(string)BGRA, pixel-aspect-ratio=(fraction)1/1, interlace-mode=(string)progressive'
  AUDIO=audio/x-raw
  # VIDEO=video/x-raw-yuv
  vfid=string
  afid="format=(string)S16LE, "
else
  gstlaunch=`which gst-launch-0.10`
  if [ X$gstlaunch != X ] ; then
    VIDEOCONVERT=ffmpegcolorspace
    VIDEO='video/x-raw-rgb, bpp=(int)32, depth=(int)32, endianness=(int)4321, red_mask=(int)65280, green_mask=(int)16711680, blue_mask=(int)-16777216, pixel-aspect-ratio=(fraction)1/1, interlaced=(boolean)false'
    AUDIO=audio/x-raw-int
    vfid=fourcc
    afid=""
  else
    echo "Could not find gst-launch-1.0 or gst-launch-0.10. Stopping"
    exit
  fi
fi

case $1 in
  you|you1|you2|youtube|youtube1|youtube2)
        if [ $1 = you2 -o $1 = youtube2 ] ; then
          auth="$youtube_auth2"
        else
          auth="$youtube_auth1"
        fi
        if [ X$auth = X ] ; then
          echo "auth was not set YouTube"
          exit 1
        fi
        ENCAUDIOFORMAT='aacparse ! audio/mpeg,mpegversion=4,stream-format=raw'
        # videoencoder="x264enc bitrate=$vbitrate key-int-max=$keyint bframes=$h264_bframes byte-stream=false aud=true tune=zerolatency"
        videoencoder="x264enc bitrate=$vbitrate bframes=$h264_bframes byte-stream=false aud=true tune=zerolatency"
        audioencoder="faac bitrate=$abitrate"
        location=$serverurl'/x/'$auth'?videoKeyframeFrequency=1&totalDatarate='$datarate' app='$youtube_app' flashVer='$flashver' swfUrl='$serverurl
        ;;
  ustream)
        videoencoder="x264enc bitrate=$vbitrate bframes=0"
        #ENCAUDIOFORMAT='audio/mpeg'
        ENCAUDIOFORMAT=mpegaudioparse
        abitrate=`echo "$abitrate / 1000" | bc`
        audioencoder="lamemp3enc bitrate=$abitrate ! mpegaudioparse"
        location="$rtmpurl/$streamkey live=1 flashver=$flashver"
        ;;
  twitch)
        if [ $vbitrate -gt 3000] ; then vbitrate=3000 ; fi
        videoencoder="x264enc bitrate=$vbitrate bframes=0"
        ENCAUDIOFORMAT=mpegaudioparse
        abitrate=`echo "$abitrate / 1000" | bc`
        audioencoder="lamemp3enc bitrate=$abitrate ! mpegaudioparse"
        location="rtmp://$twitch_server/app/$twitch_streamkey live=1 flashver=$flashver"
        ;;
  aka | akamai)
        videoencoder="x264enc bitrate=$vbitrate bframes=0"
        audioencoder="faac bitrate=$abitrate"
        ENCAUDIOFORMAT='aacparse ! audio/mpeg,mpegversion=4,stream-format=raw'
        stream_key="live=true pubUser=$akamai_user pubPasswd=$akamai_pass"
        location="rtmp://$akamai_server/EntryPoint $stream_key $akamai_flashver"
        ;;
  *)    echo 'Use youtube, akamai or ustream'
        exit
esac

ENCVIDEOFORMAT='h264parse ! video/x-h264,level=(string)'$h264_level',profile='$h264_profile
VIDEOFORMAT=$VIDEO', framerate='$framerate', width='$width', height='$height
AUDIOFORMAT=$AUDIO', '$afid' endianness=(int)1234, signed=(boolean)true, width=(int)16, depth=(int)16, rate=(int)'$audiorate', channels=(int)'$channels
TIMEOLPARMS='halignment=left valignment=bottom text="" shaded-background=true'
VIDEOSRC="videotestsrc pattern=pinwheel is-live=true ! timeoverlay $TIMEOLPARMS"
AUDIOSRC="souphttpsrc location=https://radio.llolo.lol/listen.mp3 ! icydemux ! mpegaudioparse"
# AUDIOSRC="uridecodebin uri=https://radio.llolo.lol/listen.mp3"

set -x
$gstlaunch -v $GST_DEBUG                         \
        $VIDEOSRC                               !\
        $VIDEOFORMAT                            !\
        queue                                   !\
        $VIDEOCONVERT                           !\
        $videoencoder                           !\
        $ENCVIDEOFORMAT                         !\
        queue                                   !\
        mux. $AUDIOSRC                          !\
        flvmux streamable=true name=mux         !\
        queue                                   !\
        rtmpsink location="$location"

#           $AUDIOFORMAT                            !\
#           queue                                   !\
#           $audioencoder                           !\
#           $ENCAUDIOFORMAT                         !\
