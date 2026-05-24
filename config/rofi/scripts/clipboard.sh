#!/usr/bin/env bash

# cliphist decode needs the full "ID\tcontent" line — pipe it directly
cliphist list | rofi -dmenu \
    -p "" \
    -theme ~/.config/rofi/themes/launcher.rasi | cliphist decode | wl-copy
