#!/bin/bash

declare -a options=(
"ShutDown"
"Suspend"
"Restart"
"Logout"
"Nothing"
)

shutdown="systemctl poweroff"
reboot="systemctl reboot"
Logout="i3-msg exit"


choice=$(printf '%s\n' "${options[@]}" | dmenu -i -fn 'JetBrainsMono Nerd Font:size=12' -nb '#282c34' -sb '#98c379' -sf '#282c34' -nf '#abb2bf' -p 'Do You Want To: ')

if [[ "$choice" == "ShutDown" ]]; then
	$shutdown
elif [[ "$choice" == "Restart" ]]; then
	$reboot
elif [[ "$choice" == "Suspend" ]]; then
	i3lock-fancy;
	sleep 1;
	systemctl suspend
elif [[ "$choice" == "Logout" ]]; then
	$Logout
elif [[ "$choice" == "Nothing" ]]; then
	exit 1
else
	exit 1
fi
