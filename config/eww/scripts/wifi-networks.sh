#!/usr/bin/env bash
nmcli dev wifi rescan 2>/dev/null &

declare -A SEEN
RESULTS=()
while IFS=: read -r ssid signal security; do
    [[ -z "$ssid" || "$ssid" == "--" ]] && continue
    [[ -n "${SEEN[$ssid]}" ]] && continue
    SEEN["$ssid"]=1
    signal="${signal:-0}"
    security="${security:-Open}"
    if   (( signal >= 80 )); then icon="󰤨"
    elif (( signal >= 60 )); then icon="󰤥"
    elif (( signal >= 40 )); then icon="󰤢"
    elif (( signal >= 20 )); then icon="󰤟"
    else                          icon="󰤯"
    fi
    ssid_esc="${ssid//\"/\\\"}"
    sec_esc="${security//\"/\\\"}"
    RESULTS+=("{\"ssid\":\"$ssid_esc\",\"signal\":$signal,\"security\":\"$sec_esc\",\"icon\":\"$icon\"}")
done < <(nmcli -t -f SSID,SIGNAL,SECURITY dev wifi list 2>/dev/null | sort -t: -k2 -rn | head -15)
echo "[$(IFS=,; echo "${RESULTS[*]}")]"
