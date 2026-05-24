#!/usr/bin/env bash
CURRENT=$(nmcli radio wifi 2>/dev/null)
if [[ "$CURRENT" == "enabled" ]]; then
    nmcli radio wifi off
else
    nmcli radio wifi on
fi
sleep 0.5
eww update wifi="$(~/.config/eww/scripts/wifi.sh)"
