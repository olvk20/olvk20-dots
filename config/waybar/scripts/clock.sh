#!/usr/bin/env bash
TIME=$(date +"%H:%M:%S")
DAY=$(date +"%A")
D=$(date +%e | xargs)

case $D in
    1|21|31) SUF="st" ;;
    2|22)    SUF="nd" ;;
    3|23)    SUF="rd" ;;
    *)       SUF="th" ;;
esac

echo "{\"text\":\"<span line_height='0.8'>${TIME}\\n<span size='7pt' weight='bold' foreground='white'>${DAY}, ${D}${SUF}</span></span>\"}"
