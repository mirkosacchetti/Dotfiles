#!/bin/bash
# Pick an entry from the cliphist history with fuzzel and copy it back to the clipboard.

LINE=$(cliphist list | fuzzel --dmenu) || exit 0
[[ -z $LINE ]] && exit 0
cliphist decode <<< "$LINE" | wl-copy
