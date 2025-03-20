#!/bin/bash

EAR="alsa_output.usb-C-Media_Electronics_Inc._USB_Audio_Device-00.analog-stereo"  #Earphone
SPK="alsa_output.pci-0000_26_00.1.hdmi-stereo"  #Speakers

EARPIC=~/.config/i3/headphones.png
SPKPIC=~/.config/i3/speaker.png

FIND_DEVICE=$(pactl info | awk '/Default Sink/ {print $NF}')

if [[ $FIND_DEVICE == $EAR ]]
then
	pactl set-default-sink $SPK;
	notify-send -i $SPKPIC -t 1000 'Speakers'

elif [[ $FIND_DEVICE == $SPK ]]
then
	pactl set-default-sink $EAR;
	notify-send -i $EARPIC -t 1000 'Headphones'
fi
