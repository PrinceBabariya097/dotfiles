#!/bin/bash
# Get the art URL from playerctl
url=$(playerctl metadata mpris:artUrl)

if [[ "$url" == file://* ]]; then
  # Local file (strip 'file://')
  echo "${url#file://}"
elif [[ "$url" == http* ]]; then
  # Remote URL (Spotify, etc.) - Download to a temp file
  img_path="/tmp/waybar_art.png"
  curl -s "$url" -o "$img_path"
  echo "$img_path"
else
  # Fallback/Placeholder image if no art found
  echo "/path/to/your/placeholder.png"
fi
