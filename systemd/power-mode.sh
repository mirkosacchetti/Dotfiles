#!/bin/bash
# Switches power profile based on AC/Battery status

# Check if powerprofilesctl is available
if ! command -v powerprofilesctl &> /dev/null; then
    exit 0
fi

# Detect AC status
AC_ONLINE="0"
for ac_path in /sys/class/power_supply/AC*/online /sys/class/power_supply/AC/online; do
    if [ -r "$ac_path" ]; then
        AC_ONLINE=$(cat "$ac_path")
        break
    fi
done

# Set power profile
if [ "$AC_ONLINE" = "1" ]; then
    powerprofilesctl set balanced 2>/dev/null
else
    powerprofilesctl set power-saver 2>/dev/null
fi
