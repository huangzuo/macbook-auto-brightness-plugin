#!/usr/bin/env bash

set -euo pipefail

readonly PLUGIN_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/plugins/hz.auto-brightness"
readonly SYSTEMD_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"

if command -v omarchy >/dev/null; then
  omarchy plugin disable hz.auto-brightness 2>/dev/null || true
fi

systemctl --user disable --now auto-brightness.service 2>/dev/null || true
rm -f "$HOME/.local/bin/auto-brightness"
rm -f "$HOME/.local/bin/auto-brightnessctl"
rm -f "$SYSTEMD_DIR/auto-brightness.service"
rm -f "$PLUGIN_DIR/manifest.json"
rm -f "$PLUGIN_DIR/Panel.qml"
rmdir "$PLUGIN_DIR" 2>/dev/null || true
systemctl --user daemon-reload

printf 'Removed the user service and Omarchy plugin.\n'
printf 'Configuration was preserved. Remove the kernel patch separately with sudo ./kernel/uninstall.sh.\n'
