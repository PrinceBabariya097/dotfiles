#!/usr/bin/env bash
export PATH="$PATH:$HOME/go/bin"

# Command to run when conditions are met
COMMAND_TO_RUN="music-playback"

# Title or class of the popup window
PROCESS_NAME="music-playback"
# 1. Check if popup is open
popup_open=$(pgrep -x "$PROCESS_NAME")

# 2. Check if audio is playing
audio_status=$(playerctl status 2>/dev/null)

# 3. Run command only if audio is playing AND popup is NOT open
if [[ "$audio_status" == "Playing" || "$audio_status" == "Paused" ]]; then
    if ! pgrep -x "$PROCESS_NAME" >/dev/null; then
        $COMMAND_TO_RUN &
    fi
fi
