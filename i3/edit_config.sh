#!/bin/bash

editor="kitty --class Config nvim "

declare -a options=(
"alacritty - $HOME/.config/alacritty/alacritty.yml"
"dunst - $HOME/.config/dunst/dunstrc"
"i3 - $HOME/.config/i3/config"
"kitty - $HOME/.config/kitty/kitty.conf"
"neofetch - $HOME/.config/neofetch/config.conf"
"nvim - $HOME/.config/nvim/init.vim"
"picom - $HOME/.config/picom/picom.conf"
"polybar - $HOME/.config/polybar/config"
"ranger - $HOME/.config/ranger/rc.conf"
"bashrc - $HOME/.bashrc"
"Xresources - $HOME/.Xresources"
"zshrc - $HOME/.zshrc"
"xinitrc - $HOME/.xinitrc"
"Quit"
)

choice=$(printf '%s\n' "${options[@]}" | dmenu -i -l 20 -fn 'JetBrainsMono Nerd Font:size=11' -nb '#282c34' -sb '#98c379' -sf '#282c34' -nf '#abb2bf' -p 'Edit config: ')

if [[$choice=='Quit']]; then
	echo "Program Terminated" && exit 1
elif [[ $choice ]]; then
	cfg=$(printf %s "${choice}" | awk '{printf $NF}')
	$editor $cfg
else
	echo "Program Terminated" && exit 1
fi
