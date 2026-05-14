#!/bin/bash
options="Area\nWindow\nFull Screen"
choice=$(echo -e "$options" | rofi -dmenu -p "Screenshot:")

case "$choice" in
    Area)
        hyprshot -m region
        ;;
    Window)
        hyprshot -m window
        ;;
    "Full Screen")
        hyprshot -m output
        ;;
esac
