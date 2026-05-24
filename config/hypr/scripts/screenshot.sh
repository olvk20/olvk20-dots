#!/usr/bin/env bash

SAVE_DIR="${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots"
mkdir -p "$SAVE_DIR"
TIME=$(date +'%Y-%m-%d-%H%M%S')
FILE="$SAVE_DIR/Screenshot_$TIME.png"

EDIT=false
FULL=false

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --edit) EDIT=true  ;;
        --full) FULL=true  ;;
    esac
    shift
done

if [[ "$FULL" == "true" ]]; then
    GEOMETRY=""
else
    GEOMETRY=$(slurp 2>/dev/null)
    [[ -z "$GEOMETRY" ]] && exit 0
fi

if [[ "$EDIT" == "true" ]]; then
    if [[ -n "$GEOMETRY" ]]; then
        grim -g "$GEOMETRY" - | satty --filename - --output-filename "$FILE" --copy-command wl-copy
    else
        grim - | satty --filename - --output-filename "$FILE" --copy-command wl-copy
    fi
else
    if [[ -n "$GEOMETRY" ]]; then
        grim -g "$GEOMETRY" "$FILE"
    else
        grim "$FILE"
    fi
    wl-copy < "$FILE"
fi

[[ -f "$FILE" ]] && notify-send -a "Screenshot" -i "$FILE" "Screenshot saved" "$(basename "$FILE")" &
