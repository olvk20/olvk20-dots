#!/usr/bin/env bash
emit() {
    VOL=$(pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null | grep -oP '\d+(?=%)' | head -1 || echo 0)
    MUTED=$(pactl get-sink-mute @DEFAULT_SINK@ 2>/dev/null | awk '{print $2}' || echo no)
    SINK=$(pactl get-default-sink 2>/dev/null || echo "")
    DESC=$(pactl list sinks 2>/dev/null | awk "/Name: $SINK/{found=1} found && /Description:/{sub(/.*Description: /,\"\"); print; exit}")
    V=${VOL:-0}
    if   [[ "$MUTED" == "yes" ]]; then ICON="󰝟"
    elif (( V >= 67 ));           then ICON="󰕾"
    elif (( V >= 34 ));           then ICON="󰖀"
    else                               ICON="󰕿"; fi
    python3 -c "
import json
muted = '$MUTED' == 'yes'
print(json.dumps({
    'volume':       int('$V'),
    'icon':         '$ICON',
    'sink':         '''$DESC''',
    'slider_class': 'vol-slider muted' if muted else 'vol-slider',
    'mute_class':   'pill-btn active' if muted else 'pill-btn',
    'mute_icon':    '󰝟' if muted else '󰕾',
    'mute_label':   'Unmute' if muted else 'Mute',
}))
"
}
emit
pactl subscribe 2>/dev/null | grep --line-buffered -E "'change' on (sink|server)" | while IFS= read -r _; do emit; done
