#!/usr/bin/env bash
WIFI_ON=$(nmcli radio wifi 2>/dev/null || echo "disabled")
ACTIVE=$(nmcli -t -f IN-USE,SSID,SIGNAL,SECURITY dev wifi list 2>/dev/null | grep '^\*' | head -1)
SSID=$(echo "$ACTIVE" | cut -d: -f2)
SIGNAL=$(echo "$ACTIVE" | cut -d: -f3)
SECURITY=$(echo "$ACTIVE" | cut -d: -f4)
WIFI_DEV=$(nmcli -t device status 2>/dev/null | grep ":wifi:" | grep ":connected:" | cut -d: -f1 | head -1)
IP=$(nmcli -g IP4.ADDRESS dev show "$WIFI_DEV" 2>/dev/null | head -1 | cut -d/ -f1)
SIG=${SIGNAL:-0}
if   (( SIG >= 80 )); then ICON="󰤨"
elif (( SIG >= 60 )); then ICON="󰤥"
elif (( SIG >= 40 )); then ICON="󰤢"
elif (( SIG >= 20 )); then ICON="󰤟"
else                       ICON="󰤯"; fi
[[ -z "$SSID" ]] && ICON=$([ "$WIFI_ON" = "enabled" ] && echo "󰤭" || echo "󰤮")
python3 - <<EOF
import json
connected = bool("$SSID".strip())
enabled   = "$WIFI_ON" == "enabled"
sub       = "${IP} · ${SIGNAL}% · ${SECURITY}" if connected else "WiFi is $WIFI_ON"
print(json.dumps({
    "icon":             "$ICON",
    "title":            "$SSID" if connected else "Not Connected",
    "sub":              sub,
    "ssid":             "$SSID",
    "signal":           int("$SIG") if "$SIG".isdigit() else 0,
    "toggle_class":     "pill-btn active" if enabled else "pill-btn",
    "toggle_icon":      "󰤨" if enabled else "󰤮",
    "toggle_label":     "On" if enabled else "Off",
    "toggle_cmd":       "nmcli radio wifi off" if enabled else "nmcli radio wifi on",
    "disc_class":       "pill-btn" if connected else "pill-btn disabled",
    "nav_class":        "nav-btn" if enabled else "nav-btn nav-disabled",
}))
EOF
