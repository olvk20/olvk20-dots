#!/usr/bin/env bash
fmt_time() { local s=$1; printf "%d:%02d" $(( s/60 )) $(( s%60 )); }
emit() {
    STATUS=$(playerctl status 2>/dev/null || echo "Stopped")
    PLACEHOLDER="$HOME/.config/eww/assets/art-placeholder.png"
    if [[ "$STATUS" == "Stopped" || -z "$STATUS" ]]; then
        echo "{\"title\":\"Nothing playing\",\"artist\":\"\",\"album\":\"\",\"status\":\"Stopped\",\"pos_fmt\":\"0:00\",\"len_fmt\":\"0:00\",\"progress\":0,\"shuffle\":\"Off\",\"loop\":\"None\",\"art\":\"$PLACEHOLDER\",\"play_icon\":\"\",\"loop_icon\":\"\",\"shuffle_class\":\"ctrl-btn\",\"loop_class\":\"ctrl-btn\"}"
        return
    fi
    TITLE=$(playerctl metadata title 2>/dev/null)
    ARTIST=$(playerctl metadata artist 2>/dev/null)
    ALBUM=$(playerctl metadata album 2>/dev/null)
    POS=$(playerctl metadata position 2>/dev/null | cut -d. -f1 || echo 0)
    LEN_US=$(playerctl metadata mpris:length 2>/dev/null || echo 0)
    LEN=$(( ${LEN_US:-0} / 1000000 ))
    SHUFFLE=$(playerctl shuffle 2>/dev/null || echo "Off")
    LOOP=$(playerctl loop 2>/dev/null || echo "None")
    ART=$(playerctl metadata mpris:artUrl 2>/dev/null | sed 's|file://||')
    [[ -z "$ART" || ! -f "$ART" ]] && ART="$HOME/.config/eww/assets/art-placeholder.png"
    PROG=$(( LEN > 0 ? ${POS:-0} * 100 / LEN : 0 ))
    [[ "$STATUS" == "Playing" ]] && PLAY_ICON="󰏤" || PLAY_ICON="󰐊"
    case "$LOOP" in Track) LOOP_ICON="󰑘" ;; Playlist) LOOP_ICON="󰑖" ;; *) LOOP_ICON="󰑗" ;; esac
    [[ "$SHUFFLE" == "On" ]] && SHUF_CLASS="ctrl-btn active" || SHUF_CLASS="ctrl-btn"
    [[ "$LOOP" != "None" ]] && LOOP_CLASS="ctrl-btn active" || LOOP_CLASS="ctrl-btn"
    [[ -n "$ART" ]] && HAS_ART="true" || HAS_ART="false"
    python3 -c "
import json
print(json.dumps({
    'title':         '''$TITLE''',
    'artist':        '''$ARTIST''',
    'album':         '''$ALBUM''',
    'status':        '$STATUS',
    'pos_fmt':       '$(fmt_time "${POS:-0}")',
    'len_fmt':       '$(fmt_time "$LEN")',
    'progress':      int('$PROG'),
    'shuffle':       '$SHUFFLE',
    'loop':          '$LOOP',
    'art':           '$ART',
    'play_icon':     '$PLAY_ICON',
    'loop_icon':     '$LOOP_ICON',
    'shuffle_class': '$SHUF_CLASS',
    'loop_class':    '$LOOP_CLASS',
    'has_art':       '$HAS_ART',
}))
"
}
emit
playerctl --follow metadata --format "tick" 2>/dev/null | while IFS= read -r _; do emit; done
