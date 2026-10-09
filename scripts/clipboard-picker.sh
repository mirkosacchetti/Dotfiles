#!/bin/bash
# Pick an entry from the cliphist history with the bar's picker and copy it back to the clipboard.

LINE=$(cliphist list | rustbar pick clipboard Clipboard) || exit 0
[[ -z $LINE ]] && exit 0
cliphist decode <<< "$LINE" | wl-copy
