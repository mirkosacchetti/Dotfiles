#!/bin/bash
# Pick an emoji with the bar's picker and copy it to the clipboard.

LINE=$(rustbar pick emoji Emoji < "$HOME/Dotfiles/scripts/emoji.txt") || exit 0
[[ -z $LINE ]] && exit 0
printf '%s' "${LINE%% *}" | wl-copy
notify-send -u low "Emoji" "${LINE%% *} copied to clipboard"
