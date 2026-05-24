#!/usr/bin/env bash
tuned-adm profile "$1"
sleep 1.2
eww update battery="$(~/.config/eww/scripts/battery.sh)"
