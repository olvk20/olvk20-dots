#!/usr/bin/env bash

WALLPAPER_DIR="${WALLPAPER_DIR:-$HOME/Pictures/Wallpapers}"
CURRENT_FILE="$HOME/.cache/current_wallpaper"
RELOAD_SCRIPT="$HOME/.config/hypr/scripts/matugen_reload.sh"

# Pick wallpaper — use saved one if it exists, otherwise random
if [[ -f "$CURRENT_FILE" ]] && [[ -f "$(cat "$CURRENT_FILE")" ]]; then
    WALLPAPER=$(cat "$CURRENT_FILE")
else
    WALLPAPER=$(find "$WALLPAPER_DIR" -maxdepth 1 -type f \
        \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) \
        2>/dev/null | shuf -n 1)
    echo "$WALLPAPER" > "$CURRENT_FILE"
fi

[[ -z "$WALLPAPER" ]] && exit 0

# Set wallpaper via swww
awww img "$WALLPAPER" --transition-type fade --transition-duration 0.5

# Generate matugen colors and reload everything
matugen image "$WALLPAPER" --source-color-index 0
bash "$RELOAD_SCRIPT"
