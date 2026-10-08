#!/bin/bash
# Power profile for the eww bar, polled: {"text": "ICON", "info": "balanced"}
profile=$(powerprofilesctl get 2>/dev/null)
case $profile in
    performance) printf -v icon '\xef\x83\xa7' ;;
    balanced)    printf -v icon '\xef\x89\x8e' ;;
    power-saver) printf -v icon '\xef\x81\xac' ;;
    *)           printf -v icon '\xef\x83\xa7' ;;
esac
jq -cn --arg text "$icon" --arg info "$profile" '{text: $text, info: $info}'
