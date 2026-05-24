#!/usr/bin/env bash
SSID="$1"
[[ -z "$SSID" ]] && exit 1

# Try connecting with saved profile first
if nmcli dev wifi connect "$SSID" 2>/dev/null; then
    sleep 0.8
    eww update wifi="$(~/.config/eww/scripts/wifi.sh)"
else
    # New network — open eww password prompt
    eww update wifi-connect-ssid="$SSID"
    eww update wifi-connect-pass=""
    eww close wifi-nets
    eww open wifi-password
fi
