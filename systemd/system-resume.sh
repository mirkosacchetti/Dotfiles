#!/bin/bash
# Main script called at boot and resume from suspend
# Manages LEDs and power profile

set -e

SCRIPT_DIR="/usr/local/bin"

# Disable LEDs
"$SCRIPT_DIR/disable-leds.sh" || echo "Warning: Failed to disable LEDs"

# Set power profile based on AC/Battery
"$SCRIPT_DIR/power-mode.sh" || echo "Warning: Failed to set power profile"
