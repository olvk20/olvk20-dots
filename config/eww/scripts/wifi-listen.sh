#!/usr/bin/env bash
# Event-driven wifi state — fires on actual NetworkManager changes only.
# Uses nmcli monitor to detect connect/disconnect/VPN events.

~/.config/eww/scripts/wifi.sh

nmcli monitor 2>/dev/null | while IFS= read -r line; do
    if echo "$line" | grep -qE "connected|disconnected|added|removed|connectivity|radio|unavailable|activated|activating|deactivating"; then
        sleep 0.5
        ~/.config/eww/scripts/wifi.sh
    fi
done
