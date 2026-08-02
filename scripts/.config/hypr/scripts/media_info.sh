#!/usr/bin/env bash

# Check if playerctl is installed
if ! command -v playerctl &>/dev/null; then
    echo '{"text":"","class":"stopped"}'
    exit 0
fi

status=$(playerctl status 2>/dev/null)

case "$status" in
    "Playing")
        # 🎵 icon (Nerd Font:  )
        echo '{"text":"","class":"playing"}'
        ;;
    "Paused")
        # ⏸ icon (Nerd Font:  )
        echo '{"text":"","class":"paused"}'
        ;;
    *)
        # Stopped or no player
        echo '{"text":"","class":"stopped"}'
        ;;
esac

