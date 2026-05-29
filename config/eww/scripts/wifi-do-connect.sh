#!/usr/bin/env bash
# Read SSID and password from eww variables (handles all characters safely)
SSID=$(eww get wifi-connect-ssid 2>/dev/null)
PASS=$(eww get wifi-connect-pass 2>/dev/null)

[[ -z "$SSID" ]] && exit 1

eww close wifi-password
eww open wifi-menu --screen "$(~/.config/eww/scripts/get-monitor.sh)"

if [[ -n "$PASS" ]]; then
    nmcli dev wifi connect "$SSID" password "$PASS" 2>/dev/null &
else
    nmcli dev wifi connect "$SSID" 2>/dev/null &
fi

# Clear password from memory
eww update wifi-connect-pass=""

sleep 1
eww update wifi="$(~/.config/eww/scripts/wifi.sh)"
