#!/bin/bash
# Decode a QR code from a screenshot region, adapted from omarchy-capture-qr.
# Requires: slurp, grim, zbarimg (zbar package), wl-copy.

SELECTION=$(slurp 2>/dev/null)
[[ -z $SELECTION ]] && exit 0

# Decode QR codes only. Leaving the other symbologies enabled lets dense screen
# content false-positive as an EAN or Code 39 barcode and take over the clipboard.
RESULT=$(grim -g "$SELECTION" - | zbarimg -q --raw -Sdisable -Sqrcode.enable - 2>/dev/null)

if [[ -z $RESULT ]]; then
  notify-send -u critical "No QR code found" "Select a region containing a QR code"
  exit 1
fi

# QR codes routinely carry secrets (otpauth:// 2FA setup URIs), so the decoded
# value goes to the clipboard and nowhere else, marked sensitive so clipboard
# history skips it.
printf '%s' "$RESULT" | wl-copy --sensitive
notify-send "QR code copied to clipboard"
