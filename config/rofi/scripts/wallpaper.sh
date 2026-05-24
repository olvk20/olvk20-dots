#!/usr/bin/env bash

WALLPAPER_DIR="${WALLPAPER_DIR:-$HOME/Pictures/Wallpapers}"
RELOAD_SCRIPT="$HOME/.config/hypr/scripts/matugen_reload.sh"
CURRENT_FILE="$HOME/.cache/current_wallpaper"
THUMB_DIR="$HOME/.cache/wallpaper-thumbs"
mkdir -p "$THUMB_DIR"

CURRENT=$(basename "$(cat "$CURRENT_FILE" 2>/dev/null)" 2>/dev/null)

# Build rofi entries — filename + null-sep icon path
while IFS= read -r file; do
    name=$(basename "$file")
    thumb="$THUMB_DIR/${name}.png"

    # Generate thumbnail only if missing or stale
    if [[ ! -f "$thumb" || "$file" -nt "$thumb" ]]; then
        convert "$file" -resize 160x100^ -gravity center -extent 160x100 \
            -quality 85 "$thumb" 2>/dev/null
    fi

    label="$name"
    [[ "$name" == "$CURRENT" ]] && label+="   ●"

    printf "%s\0icon\x1f%s\n" "$label" "$thumb"
done < <(find "$WALLPAPER_DIR" -maxdepth 1 -type f \
    \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) | sort) \
| rofi -dmenu \
    -p "Wallpapers" \
    -show-icons \
    -theme ~/.config/rofi/themes/launcher.rasi \
    -theme-str '
        window { width: 820px; }
        element-icon { size: 100px; border-radius: 6px; }
        element { padding: 10px 14px; }
        listview { columns: 4; lines: 3; spacing: 6px; }
        inputbar { padding: 14px 18px; }
    ' | {
    read -r CHOSEN
    [[ -z "$CHOSEN" ]] && exit 0

    # Strip ● marker
    CHOSEN_NAME="${CHOSEN%%   ●*}"
    CHOSEN_PATH="$WALLPAPER_DIR/$CHOSEN_NAME"
    [[ ! -f "$CHOSEN_PATH" ]] && exit 0

    echo "$CHOSEN_PATH" > "$CURRENT_FILE"

    awww img "$CHOSEN_PATH" --transition-type fade --transition-duration 0.5

    matugen image "$CHOSEN_PATH" --source-color-index 0 && \
        bash "$RELOAD_SCRIPT"
}
