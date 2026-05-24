#!/usr/bin/env bash
# Pure bash + awk audio device list, event-driven via pactl subscribe.
# No Python, no JSON parsing — fires only when devices actually change.

emit() {
    local DEFAULT_SINK DEFAULT_SOURCE
    DEFAULT_SINK=$(pactl get-default-sink 2>/dev/null)
    DEFAULT_SOURCE=$(pactl get-default-source 2>/dev/null)

    # Parse sinks: single pactl call, awk extracts name+description
    local SINKS="" FIRST=1
    while IFS='|' read -r name desc; do
        [[ -z "$name" ]] && continue
        local cls="list-item" dot="false" dot_char=""
        [[ "$name" == "$DEFAULT_SINK" ]] && cls="list-item active" dot="true" dot_char="●"
        [[ $FIRST -eq 0 ]] && SINKS+=","
        SINKS+="{\"name\":\"${name//\"/\\\"}\",\"description\":\"${desc//\"/\\\"}\",\"item_class\":\"$cls\",\"is_default\":$dot,\"active_dot\":\"$dot_char\"}"
        FIRST=0
    done < <(pactl list sinks 2>/dev/null | awk '
        /^\tName:/        { name = $2 }
        /^\tDescription:/ { sub(/.*Description: /, ""); print name "|" $0 }')

    # Parse sources, skip .monitor virtual sources
    local SRCS="" FIRST=1
    while IFS='|' read -r name desc; do
        [[ -z "$name" || "$name" == *.monitor ]] && continue
        local cls="list-item" dot="false" dot_char=""
        [[ "$name" == "$DEFAULT_SOURCE" ]] && cls="list-item active" dot="true" dot_char="●"
        [[ $FIRST -eq 0 ]] && SRCS+=","
        SRCS+="{\"name\":\"${name//\"/\\\"}\",\"description\":\"${desc//\"/\\\"}\",\"item_class\":\"$cls\",\"is_default\":$dot,\"active_dot\":\"$dot_char\"}"
        FIRST=0
    done < <(pactl list sources 2>/dev/null | awk '
        /^\tName:/        { name = $2 }
        /^\tDescription:/ { sub(/.*Description: /, ""); print name "|" $0 }')

    echo "{\"outputs\":[$SINKS],\"inputs\":[$SRCS]}"
}

emit

# Event-driven: re-emit only when sinks/sources are added, removed, or default changes
pactl subscribe 2>/dev/null \
    | grep --line-buffered -E "Event '(new|remove|change)' on (sink|source|server) #" \
    | while IFS= read -r _; do
        sleep 0.3
        emit
    done
