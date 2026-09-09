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
echo "[1/5] Stopping and disabling service..."
sudo systemctl stop thinkpad-system-setup.service 2>/dev/null || true
sudo systemctl disable thinkpad-system-setup.service 2>/dev/null || true
sudo rm -f /etc/systemd/system/thinkpad-system-setup.service

# Remove systemd sleep hook
echo "[2/5] Removing systemd sleep hook..."
sudo rm -f /lib/systemd/system-sleep/thinkpad-sleep-hook

# Remove logind lid drop-in (restores default lid-close suspend).
# Reload, not restart: a restart drops the session sway holds its DRM and
# input devices through, and kills the running desktop. See install.sh.
echo "[3/5] Removing logind lid drop-in..."
sudo rm -f /etc/systemd/logind.conf.d/logind-lid.conf
sudo systemctl reload systemd-logind

# Remove udev wakeup rules
echo "[4/5] Removing udev wakeup rules..."
sudo rm -f /etc/udev/rules.d/99-thinkpad-wakeup.rules
sudo udevadm control --reload

# Remove scripts
echo "[5/5] Removing scripts..."
sudo rm -f /usr/local/bin/disable-leds.sh
sudo rm -f /usr/local/bin/power-mode.sh
sudo rm -f /usr/local/bin/system-resume.sh
sudo rm -f /usr/local/bin/resuspend-if-lid-closed.sh

sudo systemctl daemon-reload

echo ""
echo "=== Uninstallation completed ==="
