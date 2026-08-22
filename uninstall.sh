#!/usr/bin/env bash

set -euo pipefail

readonly PLUGIN_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/plugins/hz.auto-brightness"
readonly SYSTEMD_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
readonly LOW_LIGHT_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/auto-brightness/kernel"
readonly PLUGIN_ID="hz.auto-brightness"

remove_plugin=true
case "${1:-}" in
  "") ;;
  --backend-only) remove_plugin=false ;;
  *)
    printf 'Usage: %s [--backend-only]\n' "$0" >&2
    exit 2
    ;;
esac

if [[ "$remove_plugin" == true ]] && command -v omarchy >/dev/null; then
  omarchy plugin disable "$PLUGIN_ID" 2>/dev/null || true
fi

systemctl --user disable --now auto-brightness.service 2>/dev/null || true
rm -f "$HOME/.local/bin/auto-brightness"
rm -f "$HOME/.local/bin/auto-brightnessctl"
rm -f "$SYSTEMD_DIR/auto-brightness.service"
if [[ "$remove_plugin" == true ]]; then
  rm -f "$PLUGIN_DIR/manifest.json"
  rm -f "$PLUGIN_DIR/Panel.qml"
  rmdir "$PLUGIN_DIR" 2>/dev/null || true
fi
rm -f "$LOW_LIGHT_DIR/install.sh"
rm -f "$LOW_LIGHT_DIR/uninstall.sh"
rm -f "$LOW_LIGHT_DIR/drivers/hwmon/applesmc.c"
rm -f "$LOW_LIGHT_DIR/packaging/Makefile"
rm -f "$LOW_LIGHT_DIR/packaging/dkms.conf"
rm -f "$LOW_LIGHT_DIR/packaging/applesmc-als.modprobe.conf"
rm -f "$LOW_LIGHT_DIR/packaging/applesmc-als.modules-load.conf"
rmdir "$LOW_LIGHT_DIR/drivers/hwmon" "$LOW_LIGHT_DIR/drivers" 2>/dev/null || true
rmdir "$LOW_LIGHT_DIR/packaging" "$LOW_LIGHT_DIR" 2>/dev/null || true
systemctl --user daemon-reload

if [[ "$remove_plugin" == true ]]; then
  printf 'Removed the user service and Omarchy plugin.\n'
else
  printf 'Removed the automatic-brightness backend.\n'
fi
printf 'Configuration was preserved. Remove the kernel patch separately with sudo ./kernel/uninstall.sh.\n'
