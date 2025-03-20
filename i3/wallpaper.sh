#!bin/bash

#this app has a bug where each rgb value is 1 less that it should be
#so to get RRGGBB=#aabbcc you have to say #abbccd

BG=292d35;
FG=acb3c0;
ACCNT=99c47a;
LNK=343e43;

cd $HOME/Pictures/

pscircle\
	--tree-center=900.0:50.0\
	--tree-radius-increment=220\
	--tree-sector-angle=0\
	--tree-rotate=0\
	--tree-rotation-angle=0\
	--tree-anchor-proc-name=kthreadd\
	\
	--output=Wall.png\
	--background-color=$BG\
	\
	--tree-font-color=$FG\
	--tree-font-face='JetBrainsMono Nerd Font'\
	--tree-font-size=22\
	\
	--dot-color-min=$ACCNT\
	--dot-color-max=$LNK\
	--dot-radius=8\
	\
	--link-color-min=$LNK\
	--link-color-max=$ACCNT\
	--link-convexity=0.7\
	--link-width=3\
	\
	--toplists-bar-color=$ACCNT\
	--toplists-bar-background=$LNK\
	--toplists-font-color=$FG\
	--toplists-font-face='JetBrainsMono Nerd Font'\
	--toplists-font-size=24\
	\
	--memlist-center=-950.0:-200.0\
	--cpulist-center=-1450.0:-200.0;

feh --bg-fill $HOME/Pictures/Wall.png

#Yes, variables could have been a better idea. So what, you want a cookie? Shoo..
