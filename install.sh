#!/usr/bin/env bash

set -euo pipefail

readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly PLUGIN_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/plugins/hz.auto-brightness"
readonly CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/auto-brightness"
readonly SYSTEMD_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
readonly PLUGIN_ID="hz.auto-brightness"

install_plugin=true
case "${1:-}" in
  "") ;;
  --backend-only) install_plugin=false ;;
  *)
    printf 'Usage: %s [--backend-only]\n' "$0" >&2
    exit 2
    ;;
esac

install -Dm0755 "$SCRIPT_DIR/bin/auto-brightness" "$HOME/.local/bin/auto-brightness"
install -Dm0755 "$SCRIPT_DIR/bin/auto-brightnessctl" "$HOME/.local/bin/auto-brightnessctl"
install -Dm0644 "$SCRIPT_DIR/systemd/auto-brightness.service" \
  "$SYSTEMD_DIR/auto-brightness.service"
if [[ "$install_plugin" == true ]]; then
  install -Dm0644 "$SCRIPT_DIR/manifest.json" "$PLUGIN_DIR/manifest.json"
  install -Dm0644 "$SCRIPT_DIR/Panel.qml" "$PLUGIN_DIR/Panel.qml"
fi
if [[ ! -e "$CONFIG_DIR/config" ]]; then
  install -Dm0600 "$SCRIPT_DIR/config/config.example" "$CONFIG_DIR/config"
fi

systemctl --user daemon-reload
systemctl --user enable --now auto-brightness.service

if [[ "$install_plugin" == true ]] && command -v omarchy >/dev/null; then
  omarchy plugin validate "$PLUGIN_DIR"
  omarchy plugin enable "$PLUGIN_ID" --section right
fi

if [[ "$install_plugin" == true ]]; then
  printf 'Installed the automatic-brightness service and Omarchy plugin.\n'
else
  printf 'Installed the automatic-brightness backend.\n'
fi
