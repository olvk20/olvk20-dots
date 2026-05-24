#!/usr/bin/env bash
RESULTS=()
while read -r _ mac name_rest; do
    [[ -z "$mac" ]] && continue
    INFO=$(bluetoothctl info "$mac" 2>/dev/null)
    IS_CONN=$(echo "$INFO" | awk '/Connected:/{print $2}')
    IS_PAIR=$(echo "$INFO" | awk '/Paired:/{print $2}')
    BAT=$(echo "$INFO" | grep -i "Battery Percentage" | grep -oP '(?<=\()\d+(?=\))' | head -1)
    if   [[ "$IS_CONN" == "yes" ]]; then STATUS="●"; CLASS="list-item active"; ICON="󰂱"; CMD="bluetoothctl disconnect"
    else                                 STATUS="${BAT:+${BAT}% 󰁹}"; [[ -z "$STATUS" && "$IS_PAIR" == "yes" ]] && STATUS="saved"
                                         CLASS="list-item"; ICON="󰂯"; CMD="bluetoothctl connect"
    fi
    name_esc="${name_rest//\"/\\\"}"
    RESULTS+=("{\"name\":\"$name_esc\",\"mac\":\"$mac\",\"status\":\"$STATUS\",\"class\":\"$CLASS\",\"icon\":\"$ICON\",\"cmd\":\"$CMD\"}")
done < <(bluetoothctl devices 2>/dev/null | grep "^Device")
echo "[$(IFS=,; echo "${RESULTS[*]}")]"
