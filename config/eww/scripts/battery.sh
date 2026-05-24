#!/usr/bin/env bash
BAT_DIR=$(ls -d /sys/class/power_supply/BAT* 2>/dev/null | head -1)
PERCENT=$(cat "$BAT_DIR/capacity" 2>/dev/null || echo 0)
STATUS=$(cat "$BAT_DIR/status" 2>/dev/null || echo "Unknown")
UPOWER=$(upower -i "$(upower -e | grep -m1 'BAT')" 2>/dev/null)
TIME_LINE=$(echo "$UPOWER" | grep "time to" | sed 's/.*time to //' | xargs)
RATE=$(echo "$UPOWER" | awk '/energy-rate/{printf "%.1f", $2; exit}')
PROFILE=$(tuned-adm active 2>/dev/null | awk '{print $NF}')
case "$STATUS" in
    Full)        TIME_STR="Fully charged" ;;
    Charging)    TIME_STR="${TIME_LINE:-calculating…} to full" ;;
    Discharging) TIME_STR="${TIME_LINE:-calculating…} remaining" ;;
    *)           TIME_STR="" ;;
esac
P=$PERCENT
if   [[ "$STATUS" == "Charging" ]]; then BAT_ICON="󰂄"
elif (( P >= 90 )); then BAT_ICON="󰁹"
elif (( P >= 80 )); then BAT_ICON="󰂂"
elif (( P >= 60 )); then BAT_ICON="󰂀"
elif (( P >= 40 )); then BAT_ICON="󰁾"
elif (( P >= 20 )); then BAT_ICON="󰁼"
else                     BAT_ICON="󰁺"; fi
python3 - <<EOF
import json
profile = "$PROFILE"
profiles = ["throughput-performance", "balanced", "powersave"]
cls = {p: ("profile-btn active" if profile == p else "profile-btn") for p in profiles}
print(json.dumps({
    "percentage":  int("$PERCENT"),
    "status":      "$STATUS",
    "time":        "$TIME_STR",
    "rate":        "${RATE:-0}",
    "rate_label":  "${RATE:-}W" if "$RATE" and "$RATE" != "0" else "",
    "profile":     profile,
    "icon":        "$BAT_ICON",
    "perf_class":  cls["throughput-performance"],
    "bal_class":   cls["balanced"],
    "saver_class": cls["powersave"],
}))
EOF
