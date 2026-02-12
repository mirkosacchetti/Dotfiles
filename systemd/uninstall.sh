#!/bin/bash
# Uninstallation script for ThinkPad system services

set -e

echo "=== ThinkPad System Setup - Uninstallation ==="
echo ""

if [ "$EUID" -eq 0 ]; then
    echo "Error: Do not run this script as root. It will use sudo when needed."
    exit 1
fi

# Stop and disable service
echo "[1/3] Stopping and disabling service..."
sudo systemctl stop thinkpad-system-setup.service 2>/dev/null || true
sudo systemctl disable thinkpad-system-setup.service 2>/dev/null || true
sudo rm -f /etc/systemd/system/thinkpad-system-setup.service

# Remove systemd sleep hook
echo "[2/3] Removing systemd sleep hook..."
sudo rm -f /lib/systemd/system-sleep/thinkpad-sleep-hook

# Remove scripts
echo "[3/3] Removing scripts..."
sudo rm -f /usr/local/bin/disable-leds.sh
sudo rm -f /usr/local/bin/power-mode.sh
sudo rm -f /usr/local/bin/system-resume.sh

sudo systemctl daemon-reload

echo ""
echo "=== Uninstallation completed ==="
