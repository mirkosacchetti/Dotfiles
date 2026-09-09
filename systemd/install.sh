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
echo "[1/6] Installing scripts to /usr/local/bin/..."
sudo install -m 755 disable-leds.sh /usr/local/bin/
sudo install -m 755 power-mode.sh /usr/local/bin/
sudo install -m 755 system-resume.sh /usr/local/bin/
sudo install -m 755 resuspend-if-lid-closed.sh /usr/local/bin/

# Install systemd sleep hook
echo "[2/6] Installing systemd sleep hook..."
sudo install -m 755 thinkpad-sleep-hook /lib/systemd/system-sleep/

# Install logind drop-in: lid handling is owned by sway (scripts/lid-eval.sh).
# Reload, never restart: restarting logind invalidates the session every
# Wayland compositor holds its DRM and input devices through, so `systemctl
# restart systemd-logind` kills the running sway session. logind is
# Type=notify-reload and re-reads its drop-ins on reload, with no session loss.
echo "[3/6] Installing logind lid drop-in..."
sudo install -m 644 -D logind-lid.conf /etc/systemd/logind.conf.d/logind-lid.conf
sudo systemctl reload systemd-logind

# Disable and remove old services
echo "[4/6] Cleaning up old services..."
for old_service in thinkpad-disable-led.service thinkpad-power-mode.service; do
    if systemctl list-unit-files | grep -q "^$old_service"; then
        echo "  - Removing $old_service"
        sudo systemctl disable "$old_service" 2>/dev/null || true
        sudo systemctl stop "$old_service" 2>/dev/null || true
        sudo rm -f "/etc/systemd/system/$old_service"
    fi
done

# Install udev wakeup rules: keep the lid/TrackPoint from waking the machine
#
# Apply to the two live devices by writing the attribute directly. Do NOT
# `udevadm trigger` the acpi subsystem to do it: that re-processes PNP0C0A,
# the ACPI battery behind /sys/class/power_supply/BAT0, and waybar 0.15.0's
# battery module aborts when a power_supply entry moves under it (the reason
# scripts/bar-loop.sh exists). The rules file is what makes it stick at boot.
echo "[5/6] Installing udev wakeup rules..."
sudo install -m 644 ../udev/99-thinkpad-wakeup.rules /etc/udev/rules.d/
sudo udevadm control --reload
for dev in /sys/devices/platform/PNP0C0E:00 /sys/bus/i2c/devices/i2c-SYNA8018:00; do
    # -e, not -w: these are root-owned, so the test must not depend on our uid.
    if [ -e "$dev/power/wakeup" ]; then
        echo disabled | sudo tee "$dev/power/wakeup" >/dev/null
    fi
done

# Install and enable new service
echo "[6/6] Installing and enabling thinkpad-system-setup.service..."
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
