#!/usr/bin/env bash

format_output() {
    local status="$1" artist="$2" title="$3"
    if [[ -z "$status" || "$status" == "Stopped" || -z "$title" ]]; then
        printf '{"text":"","class":"stopped"}\n'
        return
    fi
    local display="${artist:+$artist - }$title"
    [[ ${#display} -gt 38 ]] && display="${display:0:35}..."
    local icon
    [[ "$status" == "Paused" ]] && icon="󰏤" || icon="󰎈"
    python3 -c "
import json, sys
print(json.dumps({'text': sys.argv[1], 'class': sys.argv[2], 'tooltip': sys.argv[3]}), flush=True)
" "${icon}  ${display}" "${status}" "${title} by ${artist}"
}

# Output current state immediately on startup
format_output "$(playerctl status 2>/dev/null)" \
              "$(playerctl metadata artist 2>/dev/null)" \
              "$(playerctl metadata title 2>/dev/null)"

# Follow changes — only fires when something actually changes
while true; do
    playerctl --follow metadata \
        --format '{{status}}|{{artist}}|{{title}}' 2>/dev/null \
    | while IFS='|' read -r status artist title; do
        format_output "$status" "$artist" "$title"
    done
    # Player exited — clear the module and wait before retrying
    printf '{"text":"","class":"stopped"}\n'
    sleep 2
done
