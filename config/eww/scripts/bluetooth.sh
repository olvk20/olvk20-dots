#!/usr/bin/env bash
BT_POWER=$(bluetoothctl show 2>/dev/null | awk '/Powered:/{print $2}')
BT_MAC=$(bluetoothctl devices Connected 2>/dev/null | awk '{print $2}' | head -1)
if [[ -n "$BT_MAC" ]]; then
    INFO=$(bluetoothctl info "$BT_MAC" 2>/dev/null)
    BT_NAME=$(echo "$INFO" | awk -F': ' '/^\tName:/{print $2}')
    BT_BAT=$(echo "$INFO" | grep -i "Battery Percentage" | grep -oP '(?<=\()\d+(?=\))' | head -1)
    CONNECTED=true; ICON="󰂱"
else
    BT_NAME="Not Connected"; BT_BAT=""; CONNECTED=false
    ICON=$([ "$BT_POWER" = "yes" ] && echo "󰂯" || echo "󰂲")
fi
python3 - <<EOF
import json
connected = $([[ "$CONNECTED" == "true" ]] && echo "True" || echo "False")
enabled   = "$BT_POWER" == "yes"
sub = "$BT_MAC" + (" · ${BT_BAT}% 󰁹" if "$BT_BAT" else "") if connected else "Bluetooth is " + ("on" if "$BT_POWER" == "yes" else "off") + ""
print(json.dumps({
    "icon":           "$ICON",
    "name":           "$BT_NAME",
    "mac":            "$BT_MAC",
    "sub":            sub,
    "toggle_class":   "pill-btn active" if enabled else "pill-btn",
    "toggle_icon":    "󰂯" if enabled else "󰂲",
    "toggle_label":   "On" if enabled else "Off",
    "toggle_cmd":     "bluetoothctl power " + ("off" if enabled else "on"),
    "disc_class":     "pill-btn" if connected else "pill-btn disabled",
    "nav_class":      "nav-btn" if enabled else "nav-btn nav-disabled",
}))
EOF
