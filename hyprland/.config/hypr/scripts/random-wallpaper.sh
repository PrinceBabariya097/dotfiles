#!/bin/bash
# Directory containing wallpapers
WALLPAPER_DIR="$HOME/Pictures/wallpaper"

# Get random wallpaper (follow symlinks with -L)
WALLPAPER=$(find -L "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" \) | shuf -n 1)

if [ -z "$WALLPAPER" ]; then
    echo "No wallpapers found in $WALLPAPER_DIR"
    exit 1
fi

echo "Setting wallpaper: $WALLPAPER"
# Preload the wallpaper first
hyprctl hyprpaper preload "$WALLPAPER"
# Then set it as wallpaper
hyprctl hyprpaper wallpaper ",$WALLPAPER"
