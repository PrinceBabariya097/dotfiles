#!/bin/bash

# Battery thresholds and brightness levels
LOW_BATTERY=20
CRITICAL_BATTERY=10
BRIGHTNESS_LOW=40%
BRIGHTNESS_CRITICAL=20%
BRIGHTNESS_FULL=100%
BATTERY_PATH="/sys/class/power_supply/BAT1"

# State tracking variables
low_battery_notified=false
critical_battery_notified=false
full_battery_notified=false
previous_status=""

# Function to reset notification states based on battery level changes
reset_notification_states() {
    local current_battery_level=$1

    # Reset low battery notification if battery goes above low threshold
    if [ "$current_battery_level" -gt "$LOW_BATTERY" ]; then
        low_battery_notified=false
    fi

    # Reset critical battery notification if battery goes above critical threshold
    if [ "$current_battery_level" -gt "$CRITICAL_BATTERY" ]; then
        critical_battery_notified=false
    fi

    # Reset full battery notification if battery drops below 100%
    if [ "$current_battery_level" -lt 100 ]; then
        full_battery_notified=false
    fi
}

# Function to set brightness level based on battery status
set_brightness_level_on_battery() {
    local current_battery_level=$1
    local current_battery_status=$2

    # Reset notification states based on current battery level
    reset_notification_states "$current_battery_level"

    # Handle critical battery (below 10%)
    if [ "$current_battery_level" -lt "$CRITICAL_BATTERY" ]; then
        if [ "$critical_battery_notified" = false ]; then
            notify-send "Critical Battery" "Please charge your device immediately. Battery: ${current_battery_level}%"
            critical_battery_notified=true
        fi
        brightnessctl set "$BRIGHTNESS_CRITICAL"

    # Handle low battery (below 20% but above critical)
    elif [ "$current_battery_level" -lt "$LOW_BATTERY" ]; then
        if [ "$low_battery_notified" = false ]; then
            notify-send "Low Battery" "Please charge your device. Battery: ${current_battery_level}%"
            low_battery_notified=true
        fi
        brightnessctl set "$BRIGHTNESS_LOW"

    # Handle full battery (100% and charging/full)
    elif [ "$current_battery_level" -eq 100 ]; then
        if [ "$current_battery_status" == "Charging" ] || [ "$current_battery_status" == "Full" ]; then
            if [ "$full_battery_notified" = false ]; then
                notify-send "Battery Full" "Your device is fully charged."
                full_battery_notified=true
            fi
            # brightnessctl set "$BRIGHTNESS_FULL"
        fi

    # Handle normal battery levels (restore full brightness)
    else
        # brightnessctl set "$BRIGHTNESS_FULL"
    fi
}

# Main function to check battery and manage notifications/brightness
check_battery() {
    if [ ! -d "$BATTERY_PATH" ]; then
        notify-send "Battery Not Found" "Please check your battery status. Path: $BATTERY_PATH"
        exit 1
    fi

    while true; do
        local battery_level=$(cat "$BATTERY_PATH/capacity")
        local battery_status=$(cat "$BATTERY_PATH/status")

        echo "$(date): Battery: $battery_level%, Status: $battery_status" >> /tmp/battery_debug.log

        set_brightness_level_on_battery "$battery_level" "$battery_status"

        # Adjust sleep interval based on battery level
        if [ "$battery_level" -lt "$CRITICAL_BATTERY" ]; then
            sleep 10  # Check frequently when critical
        elif [ "$battery_level" -lt "$LOW_BATTERY" ]; then
            sleep 20  # Check moderately when low
        else
            sleep 60  # Check less frequently when healthy
        fi
    done
}

# Start the battery check
check_battery
