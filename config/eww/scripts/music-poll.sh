#!/usr/bin/env bash
PLACEHOLDER="$HOME/.config/eww/assets/art-placeholder.png"
ART_CACHE="$HOME/.cache/eww-art"
mkdir -p "$ART_CACHE"

export STATUS="$(playerctl status 2>/dev/null || echo Stopped)"
export TITLE="$(playerctl metadata title 2>/dev/null)"
export ARTIST="$(playerctl metadata artist 2>/dev/null)"
export ALBUM="$(playerctl metadata album 2>/dev/null)"
export POS="$(playerctl position 2>/dev/null | cut -d. -f1 || echo 0)"
LEN_US="$(playerctl metadata mpris:length 2>/dev/null || echo 0)"
export LEN=$(( ${LEN_US:-0} / 1000000 ))
export SHUFFLE="$(playerctl shuffle 2>/dev/null || echo Off)"
export LOOP="$(playerctl loop 2>/dev/null || echo None)"

ART_URL="$(playerctl metadata mpris:artUrl 2>/dev/null)"
if [[ "$ART_URL" =~ ^https?:// ]]; then
    HASH=$(echo "$ART_URL" | md5sum | cut -d' ' -f1)
    CACHED="$ART_CACHE/$HASH.jpg"
    if [[ ! -f "$CACHED" ]]; then
        curl -s "$ART_URL" | convert - -resize 160x160^ -gravity center -extent 160x160 "$CACHED" 2>/dev/null
    fi
    export ART="$CACHED"
elif [[ -n "$ART_URL" && -f "${ART_URL#file://}" ]]; then
    export ART="${ART_URL#file://}"
else
    export ART="$PLACEHOLDER"
fi
export PLACEHOLDER

python3 - <<'EOF'
import json, os

status  = os.environ.get('STATUS',  'Stopped')
title   = os.environ.get('TITLE',   '')
artist  = os.environ.get('ARTIST',  '')
album   = os.environ.get('ALBUM',   '')
art     = os.environ.get('ART',     os.environ.get('PLACEHOLDER', ''))
shuffle = os.environ.get('SHUFFLE', 'Off')
loop    = os.environ.get('LOOP',    'None')

pos    = int(os.environ.get('POS', '0') or '0')
length = int(os.environ.get('LEN', '0') or '0')

progress  = pos * 100 // length if length > 0 else 0
pos_fmt   = f'{pos//60}:{pos%60:02d}'
len_fmt   = f'{length//60}:{length%60:02d}'

play_icon  = '\U000F03E4' if status == 'Playing' else '\U000F040A'
loop_icons = {'Track': '\U000F0458', 'Playlist': '\U000F0456'}
loop_icon  = loop_icons.get(loop, '\U000F0457')

shuf_class = 'ctrl-btn active' if shuffle == 'On'  else 'ctrl-btn'
loop_class = 'ctrl-btn active' if loop   != 'None' else 'ctrl-btn'

print(json.dumps({
    'title':         title,
    'artist':        artist,
    'album':         album,
    'pos_fmt':       pos_fmt,
    'len_fmt':       len_fmt,
    'progress':      progress,
    'art':           art,
    'play_icon':     play_icon,
    'loop_icon':     loop_icon,
    'shuffle_class': shuf_class,
    'loop_class':    loop_class,
}))
EOF
