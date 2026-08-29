#!/bin/bash
# Pick a pixel color to the clipboard as #rrggbb (slurp point + grim, no extra tools).

POINT=$(slurp -p 2>/dev/null)
[[ -z $POINT ]] && exit 0

HEX=$(grim -g "$POINT" -t ppm - | python -c "
import sys
from PIL import Image
im = Image.open(sys.stdin.buffer).convert('RGB')
print('#%02x%02x%02x' % im.getpixel((0, 0)))
")
[[ -z $HEX ]] && exit 1

printf '%s' "$HEX" | wl-copy
notify-send -u low "Color picker" "$HEX copied to clipboard"
