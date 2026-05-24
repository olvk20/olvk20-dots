#!/usr/bin/env bash

# Flatten any {"color": "#hex"} objects matugen v4 may emit into plain #hex
TEXT_FILES=(
    "$HOME/.config/hypr/matugen_colors.json"
    "$HOME/.config/kitty/kitty-matugen-colors.conf"
    "$HOME/.config/nvim/matugen_colors.lua"
    "$HOME/.config/cava/colors"
    "$HOME/.config/swayosd/style.css"
    "$HOME/.config/rofi/theme.rasi"
    "$HOME/.cache/matugen/colors-gtk.css"
    "$HOME/.config/qt5ct/colors/matugen.conf"
    "$HOME/.config/qt6ct/colors/matugen.conf"
    "$HOME/.config/qt5ct/qss/matugen-style.qss"
    "$HOME/.config/qt6ct/qss/matugen-style.qss"
    "$HOME/.config/hypr/colors.conf"
)

for file in "${TEXT_FILES[@]}"; do
    if [ -f "$file" ] && [ -w "$file" ]; then
        sed -i -E 's/\{[[:space:]]*"color":[[:space:]]*"([^"]+)"[[:space:]]*\}/\1/g' "$file"
    fi
done

# Reload Kitty
killall -USR1 kitty 2>/dev/null

# Compile eww theme with sassc (bypasses grass + @charset issue) and reload eww
sassc "$HOME/.config/eww/eww-theme.scss" \
  | sed '/@charset/d' \
  > "$HOME/.config/eww/eww.css" 2>/dev/null
rm -f "$HOME/.config/eww/eww.scss"
eww kill 2>/dev/null; sleep 0.2; eww daemon &>/dev/null & disown

# Reload Waybar CSS
pkill -SIGUSR2 waybar 2>/dev/null

# Reload swaync CSS
swaync-client --reload-css 2>/dev/null

# Reload CAVA
cat ~/.config/cava/config_base ~/.config/cava/colors > ~/.config/cava/config 2>/dev/null
pgrep -x cava > /dev/null && killall -USR1 cava 2>/dev/null

# Restart swayosd
killall swayosd-server 2>/dev/null
swayosd-server --top-margin 0.9 --style "$HOME/.config/swayosd/style.css" &>/dev/null & disown

# GTK live-reload
if command -v gsettings &>/dev/null; then
    gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita'
    sleep 0.05
    gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark'
    gsettings set org.gnome.desktop.interface color-scheme 'default'
    sleep 0.05
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
fi
