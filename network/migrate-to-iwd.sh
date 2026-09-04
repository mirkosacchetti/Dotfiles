#!/bin/bash
# Migrazione: NetworkManager -> iwd standalone + systemd-networkd + systemd-resolved
# Rollback: rollback-to-nm.sh nella stessa directory
set -euo pipefail
cd "$(dirname "$0")"

echo "== installo i config"
install -Dm644 iwd-main.conf /etc/iwd/main.conf
install -Dm644 20-wired.network /etc/systemd/network/20-wired.network
install -Dm644 resolved-no-mdns.conf /etc/systemd/resolved.conf.d/no-mdns.conf

echo "== abilito networkd + resolved"
systemctl enable --now systemd-networkd systemd-resolved
ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

echo "== spengo NetworkManager, riavvio iwd"
systemctl disable --now NetworkManager
systemctl restart iwd

echo "== attendo la riconnessione Wi-Fi (max 20s)"
for i in $(seq 20); do
  ip route | grep -q '^default.*wlan0' && break
  sleep 1
done

echo "== verifica"
iwctl station wlan0 show | grep -E 'State|Connected network' || true
ip -br addr show wlan0
ip route | head -3
resolvectl query archlinux.org >/dev/null && echo "DNS: OK"
ping -c1 -W3 archlinux.org >/dev/null && echo "Internet: OK"
echo "== migrazione completata"
