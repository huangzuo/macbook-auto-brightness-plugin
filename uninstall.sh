#!/usr/bin/env bash

set -euo pipefail

readonly PLUGIN_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/plugins/hz.auto-brightness"
readonly SYSTEMD_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
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
  # Omarchy Shell may leave hot-reload backups beside the plugin files.
  rm -f -- "$PLUGIN_DIR"/*.bak.* 2>/dev/null || true
  rmdir "$PLUGIN_DIR" 2>/dev/null || true
fi
systemctl --user daemon-reload

if [[ "$remove_plugin" == true ]]; then
  printf 'Removed the user service and Omarchy plugin.\n'
else
  printf 'Removed the automatic-brightness backend.\n'
fi
printf 'Configuration was preserved.\n'
