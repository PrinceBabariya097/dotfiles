#!/bin/bash

LOW_BATTERY=20
CRITICAL_BATTERY=10
BRIGHTNESS_LOW=40
BRIGHTNESS_CRITICAL=20

BRIGHTNESS_DATA=$(brightnessctl)

check_bettary() {

local bat_path="/sys/class/power_supply/BAT1"

        battery_level=$(cat "$bat_path/capacity")
    set_brightness_level_on_bettart(){
if [ -e "$bat_path" ]; then
    if [ "$battery_level" -lt "$LOW_BATTERY" ]; then
        $(notify-send "Low Battery" "Please charge your device.")
        $(brightnessctl set "$BRIGHTNESS_LOW")
    elif [ "$battery_level" -lt "$CRITICAL_BATTERY" ]; then
        $(notify-send "Critical Battery" "Please charge your device immediately.")
        $(brightnessctl set "$BRIGHTNESS_CRITICAL")
    elif [ "$battery_level" -eq 100 ]; then
        $(notify-send "Battery Full" "Your device is fully charged.")
        if [$(cat "$bat_path/status") -eq "charging"]; then
            $(notify-send "Battery Charging" "Your device is charging.")
            $(brightnessctl set 100%)
    fi
else
    $(notify-send "Battery Not Found" "Please check your battery status.")
fi
    }

    while true; do
        if [ "$battery_level" -lt "$CRITICAL_BATTERY" ]; then
            sleep 10
        elif [ "$battery_level" -lt "$LOW_BATTERY" ]; then
            sleep 20
        else
            sleep 40
        fi
    set_brightness_level_on_bettart
done
}

check_bettary
