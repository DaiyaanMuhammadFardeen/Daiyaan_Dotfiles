#!/bin/bash

# Script to toggle between light and dark KDE themes and update Kitty config

# Get current LookAndFeelPackage
current_theme=$(kreadconfig6 --file kdeglobals --group KDE --key LookAndFeelPackage)

if [ "$current_theme" = "org.kde.breezedark.desktop" ]; then
    # Switch to light theme
    lookandfeeltool -a org.kde.breeze.desktop
    cp ~/Repositories/Daiyaan_Dotfiles/kitty/light.kitty.conf ~/.config/kitty/kitty.conf
else
    # Switch to dark theme
    lookandfeeltool -a org.kde.breezedark.desktop
    cp ~/Repositories/Daiyaan_Dotfiles/kitty/dark.kitty.conf ~/.config/kitty/kitty.conf
fi

# Reload Kitty config (assuming single instance or it's okay to signal all)
pkill -USR1 kitty
