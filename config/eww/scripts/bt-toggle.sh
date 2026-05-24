#!/usr/bin/env bash
POWERED=$(bluetoothctl show 2>/dev/null | awk '/Powered:/{print $2}')
if [[ "$POWERED" == "yes" ]]; then
    bluetoothctl power off
else
    bluetoothctl power on
fi
sleep 0.4
eww update bluetooth="$(~/.config/eww/scripts/bluetooth.sh)"
