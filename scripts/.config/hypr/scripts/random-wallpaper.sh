#!/bin/bash
# Directory containing wallpapers
WALLPAPER_DIR="$HOME/Pictures/wallpaper"

# Get random wallpaper (follow symlinks with -L)
WALLPAPER=$(find -L "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" \) | shuf -n 1)

if [ -z "$WALLPAPER" ]; then
    echo "No wallpapers found in $WALLPAPER_DIR"
    exit 1
fi

# Then set it as wallpaper
hyprctl hyprpaper wallpaper ",$WALLPAPER"

# Update the symlink so hyprlock knows where to look
ln -sf "$WALLPAPER" "$HOME/.cache/current_wallpaper"

# Extract colors and update theme dynamically using wallust 
# config file is in wallust/wallust.toml
~/.cargo/bin/wallust run -s -q ~/.cache/current_wallpaper
# Force-kill any existing waybar processes (using pkill instead of killall)
pkill -f waybar

# Give the system a half-second to completely clear the old bars
sleep 0.5

# Start ONE fresh waybar in the background so it catches the new colors
waybar > /dev/null 2>&1 & disown
