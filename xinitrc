#!/usr/bin/env bash
#
# ~/.xinitrc
#
# Check if command exists
has() {
    command -v "$1" > /dev/null 2>&1
}

# Keyboard stuffs
# * Capslock → Ctrl
setxkbmap -option ctrl:nocaps

#xset -b            # Stop beeping at me (A.K.A turn off PC speaker)
#xset r rate 330 60 # Set keyboard repeat rate

# https://github.com/alols/xcape
has xcape && xcape -t 300 -e 'Control_L=Escape'
