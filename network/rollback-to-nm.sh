#!/bin/bash
# Rollback: torna a NetworkManager (backend iwd) come prima della migrazione
set -euo pipefail

systemctl disable --now systemd-networkd systemd-resolved
rm -f /etc/iwd/main.conf /etc/systemd/network/20-wired.network
rm -f /etc/resolv.conf   # NetworkManager lo rigenera
systemctl restart iwd
systemctl enable --now NetworkManager
sleep 5
nmcli dev status
ping -c1 -W3 archlinux.org >/dev/null && echo "Internet: OK"
echo "== rollback completato"
