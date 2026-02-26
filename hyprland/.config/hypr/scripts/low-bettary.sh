#!/bin/bash
# Battery thresholds and brightness levels
LOW_BATTERY=20
CRITICAL_BATTERY=10
BRIGHTNESS_LOW=40%
BRIGHTNESS_CRITICAL=20%
BRIGHTNESS_FULL=100%
BATTERY_PATH="/sys/class/power_supply/BAT1"

# Battery icons (using system icons or fallback to text)
ICON_FULL="battery-full"
ICON_GOOD="battery-good"
ICON_LOW="battery-low"
ICON_CRITICAL="battery-caution"
ICON_CHARGING="battery-full-charging"

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
      notify-send \
        --urgency=critical \
        --icon="$ICON_CRITICAL" \
        --app-name="Battery Monitor" \
        "Critical Battery" \
        "Please charge your device immediately. Battery: ${current_battery_level}%"
      critical_battery_notified=true
    fi
    brightnessctl set "$BRIGHTNESS_CRITICAL"

  # Handle low battery (below 20% but above critical)
  elif [ "$current_battery_level" -lt "$LOW_BATTERY" ]; then
    if [ "$low_battery_notified" = false ]; then
      notify-send \
        --urgency=normal \
        --icon="$ICON_LOW" \
        --app-name="Battery Monitor" \
        "Low Battery" \
        "Please charge your device. Battery: ${current_battery_level}%"
      low_battery_notified=true
    fi
    brightnessctl set "$BRIGHTNESS_LOW"

  # Handle full battery (100% and charging/full)
  elif [ "$current_battery_level" -eq 100 ]; then
    if [ "$current_battery_status" == "Charging" ] || [ "$current_battery_status" == "Full" ]; then
      if [ "$full_battery_notified" = false ]; then
        notify-send \
          --urgency=low \
          --icon="$ICON_FULL" \
          --app-name="Battery Monitor" \
          "Battery Full" \
          "Your device is fully charged. You can unplug the charger."
        full_battery_notified=true
      fi
      # brightnessctl set "$BRIGHTNESS_FULL"
    fi

    # Handle normal battery levels (restore full brightness)
    # else
    # brightnessctl set "$BRIGHTNESS_FULL"
  fi
}

# Function to send charging status notification
notify_charging_status() {
  local battery_level=$1
  local battery_status=$2

  if [ "$battery_status" == "Charging" ]; then
    notify-send \
      --urgency=low \
      --icon="$ICON_CHARGING" \
      --app-name="Battery Monitor" \
      "Charging" \
      "Battery is charging: ${battery_level}%"
  elif [ "$battery_status" == "Discharging" ]; then
    notify-send \
      --urgency=low \
      --icon="$ICON_GOOD" \
      --app-name="Battery Monitor" \
      "Unplugged" \
      "Running on battery: ${battery_level}%"
  fi
}

# Main function to check battery and manage notifications/brightness
check_battery() {
  if [ ! -d "$BATTERY_PATH" ]; then
    notify-send \
      --urgency=critical \
      --icon="dialog-error" \
      --app-name="Battery Monitor" \
      "Battery Not Found" \
      "Please check your battery status. Path: $BATTERY_PATH"
    exit 1
  fi

  while true; do
    local battery_level=$(cat "$BATTERY_PATH/capacity")
    local battery_status=$(cat "$BATTERY_PATH/status")

    echo "$(date): Battery: $battery_level%, Status: $battery_status" >>/tmp/battery_debug.log

    # Notify on status change (plugged in / unplugged)
    if [ "$battery_status" != "$previous_status" ] && [ -n "$previous_status" ]; then
      notify_charging_status "$battery_level" "$battery_status"
    fi

    previous_status="$battery_status"

    # Only apply battery management when discharging
    if [ "$battery_status" == "Discharging" ]; then
      set_brightness_level_on_battery "$battery_level" "$battery_status"
    else
      # Reset notification states when charging
      reset_notification_states "$battery_level"
      # Check for full battery notification when charging
      if [ "$battery_level" -eq 100 ]; then
        set_brightness_level_on_battery "$battery_level" "$battery_status"
      fi
    fi

    # Adjust sleep interval based on battery level
    if [ "$battery_level" -lt "$CRITICAL_BATTERY" ]; then
      sleep 10 # Check frequently when critical
    elif [ "$battery_level" -lt "$LOW_BATTERY" ]; then
      sleep 20 # Check moderately when low
    else
      sleep 60 # Check less frequently when healthy
    fi
  done
}

# Start the battery check
check_battery
