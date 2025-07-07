#!/bin/bash

LOW_BATTERY=20
CRITICAL_BATTERY=10
BRIGHTNESS_LOW=40% # Use percentage for brightnessctl set
BRIGHTNESS_CRITICAL=20% # Use percentage for brightnessctl set
BRIGHTNESS_FULL=100% # Use percentage for brightnessctl set

BATTERY_PATH="/sys/class/power_supply/BAT1"

# Function to set brightness level based on battery status
set_brightness_level_on_battery() {
    local current_battery_level=$1
    local current_battery_status=$2

    if [ "$current_battery_level" -lt "$CRITICAL_BATTERY" ]; then
        notify-send "Critical Battery" "Please charge your device immediately. Battery: ${current_battery_level}%"
        brightnessctl set "$BRIGHTNESS_CRITICAL"
    elif [ "$current_battery_level" -lt "$LOW_BATTERY" ]; then
        notify-send "Low Battery" "Please charge your device. Battery: ${current_battery_level}%"
        brightnessctl set "$BRIGHTNESS_LOW"
    elif [ "$current_battery_level" -eq 100 ]; then
        if [ "$current_battery_status" == "Charging" ] || [ "$current_battery_status" == "Full" ]; then
            notify-send "Battery Full" "Your device is fully charged."
        fi
    fi
}

# Main function to check battery and manage notifications/brightness
check_battery() {
    if [ ! -d "$BATTERY_PATH" ]; then
        notify-send "Battery Not Found" "Please check your battery status. Path: $BATTERY_PATH"
        exit 1 # Exit if battery path doesn't exist
    fi

    while true; do
        local battery_level=$(cat "$BATTERY_PATH/capacity")
        local battery_status=$(cat "$BATTERY_PATH/status")

        echo "Battery: $battery_level%, Status: $battery_status" >> /tmp/battery_debug.log

        set_brightness_level_on_battery "$battery_level" "$battery_status"

        if [ "$battery_level" -lt "$CRITICAL_BATTERY" ]; then
            sleep 10
        elif [ "$battery_level" -lt "$LOW_BATTERY" ]; then
            sleep 20
        else
            sleep 60 # Check less frequently when battery is healthy
        fi
    done
}

# Start the battery check
check_battery
