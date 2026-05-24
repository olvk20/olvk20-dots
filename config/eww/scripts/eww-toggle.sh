#!/usr/bin/env bash
# Toggle a system eww menu, closing all other system menus first.
# Music menu is excluded — it can coexist with everything.
MENU="$1"
SYSTEM="wifi-menu wifi-nets wifi-password bt-menu bt-scan vol-menu power-menu"

if eww list-windows 2>/dev/null | grep -q "^\*${MENU}$"; then
    eww close "$MENU"
else
    eww close $SYSTEM 2>/dev/null
    # Force-refresh data for wifi/bt before opening so menu is never stale
    case "$MENU" in
        wifi-menu)  eww update wifi="$(~/.config/eww/scripts/wifi.sh)" ;;
        bt-menu)    eww update bluetooth="$(~/.config/eww/scripts/bluetooth.sh)" ;;
    esac
    eww open "$MENU"
fi
