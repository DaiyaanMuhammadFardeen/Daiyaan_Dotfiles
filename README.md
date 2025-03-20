A small note for Daiyaan. If you have done a new install of any linux distro. Please swap the Caps_Lock key to Escape key

First Method:\
  --> cd /usr/share/X11/xkb/keycodes\
  --> sudo vim evdev\
  --> Search for /CAPS and /ESC and change the keycodes\

Second Methond:\
  --> mkdir -p /usr/local/share/kbd/keymaps/\
  --> sudo vim /usr/local/share/kbd/keymaps/personal.map\
  -->  keycode 1 = Caps_Lock\
   2   │ keycode 58 = Escape

Third Method:\
  --> setxkbmap -option caps:excape
   
Third method is preferred. As for me, I did them add at once. So I don't really know which of them worked 🤪

For more details, head on to <a href="https://wiki.archlinux.org/title/Linux_console/Keyboard_configuration#Persistent_configuration"> ArchWiki </a> For details
