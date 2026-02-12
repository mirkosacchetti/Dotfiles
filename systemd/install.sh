#!/bin/bash
# Installation script for ThinkPad system services

set -e

echo "=== ThinkPad System Setup - Installation ==="
echo ""

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo "Error: Do not run this script as root. It will use sudo when needed."
    exit 1
fi

# Install scripts
echo "[1/4] Installing scripts to /usr/local/bin/..."
sudo install -m 755 disable-leds.sh /usr/local/bin/
sudo install -m 755 power-mode.sh /usr/local/bin/
sudo install -m 755 system-resume.sh /usr/local/bin/

# Install systemd sleep hook
echo "[2/4] Installing systemd sleep hook..."
sudo install -m 755 thinkpad-sleep-hook /lib/systemd/system-sleep/

# Disable and remove old services
echo "[3/4] Cleaning up old services..."
for old_service in thinkpad-disable-led.service thinkpad-power-mode.service; do
    if systemctl list-unit-files | grep -q "^$old_service"; then
        echo "  - Removing $old_service"
        sudo systemctl disable "$old_service" 2>/dev/null || true
        sudo systemctl stop "$old_service" 2>/dev/null || true
        sudo rm -f "/etc/systemd/system/$old_service"
    fi
done

# Install and enable new service
echo "[4/4] Installing and enabling thinkpad-system-setup.service..."
sudo install -m 644 thinkpad-system-setup.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable thinkpad-system-setup.service
sudo systemctl start thinkpad-system-setup.service

echo ""
echo "=== Installation completed successfully! ==="
echo ""
echo "Service status:"
sudo systemctl status thinkpad-system-setup.service --no-pager -l
echo ""
echo "Test with: sudo systemctl suspend"
