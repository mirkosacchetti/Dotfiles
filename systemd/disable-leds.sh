#!/bin/bash
# Disables ThinkPad LEDs (red logo, lid logo dot, micmute)

LED_PATHS=(
    "/sys/class/leds/tpacpi::power/brightness"
    "/sys/class/leds/tpacpi::lid_logo_dot/brightness"
    "/sys/class/leds/platform::micmute/brightness"
)

for led in "${LED_PATHS[@]}"; do
    if [ -w "$led" ]; then
        echo 0 > "$led"
    fi
done
