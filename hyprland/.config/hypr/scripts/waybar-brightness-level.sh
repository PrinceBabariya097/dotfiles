#!/bin/bash

# --- Configuration ---
# You might need to change 'intel_backlight' to your specific device name.
# Run 'brightnessctl info' to find your device.
DEVICE="intel_backlight"

# --- Functions ---
get_brightness() {
    # Get current brightness percentage
    # brightnessctl -d "$DEVICE" g retrieves current level
    # brightnessctl -d "$DEVICE" m retrieves max level
    # We calculate (current / max) * 100
    current=$(brightnessctl -d "$DEVICE" g)
    max=$(brightnessctl -d "$DEVICE" m)
    percentage=$((current * 100 / max))
    echo "$percentage"
}

increase_brightness() {
    brightnessctl -d "$DEVICE" set +5%
}

decrease_brightness() {
    brightnessctl -d "$DEVICE" set 5%-
}

# --- Main Logic ---
case "$1" in
    "up")
        increase_brightness
        ;;
    "down")
        decrease_brightness
        ;;
    *)
        current_level=$(get_brightness)
        if (( current_level > 80 )); then
            icon="󰛨" # High brightness icon
        elif (( current_level > 50 )); then
            icon="󰛩" # Medium brightness icon
        elif (( current_level > 20 )); then
            icon="󰛪" # Low brightness icon
        else
            icon="󰛫" # Very low/off brightness icon
        fi

        # Output JSON for Waybar
        echo "{\"text\":\"$icon $current_level%\", \"tooltip\":\"Brightness: $current_level%\"}"
        ;;
esac
