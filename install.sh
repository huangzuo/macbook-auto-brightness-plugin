#!/usr/bin/env bash

set -euo pipefail

readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly PLUGIN_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/plugins/hz.auto-brightness"
readonly CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/auto-brightness"
readonly SYSTEMD_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
readonly LOW_LIGHT_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/auto-brightness/kernel"
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
install -Dm0755 "$SCRIPT_DIR/kernel/install.sh" "$LOW_LIGHT_DIR/install.sh"
install -Dm0755 "$SCRIPT_DIR/kernel/uninstall.sh" "$LOW_LIGHT_DIR/uninstall.sh"
install -Dm0644 "$SCRIPT_DIR/kernel/drivers/hwmon/applesmc.c" \
  "$LOW_LIGHT_DIR/drivers/hwmon/applesmc.c"
install -Dm0644 "$SCRIPT_DIR/kernel/packaging/Makefile" "$LOW_LIGHT_DIR/packaging/Makefile"
install -Dm0644 "$SCRIPT_DIR/kernel/packaging/dkms.conf" "$LOW_LIGHT_DIR/packaging/dkms.conf"
install -Dm0644 "$SCRIPT_DIR/kernel/packaging/applesmc-als.modprobe.conf" \
  "$LOW_LIGHT_DIR/packaging/applesmc-als.modprobe.conf"
install -Dm0644 "$SCRIPT_DIR/kernel/packaging/applesmc-als.modules-load.conf" \
  "$LOW_LIGHT_DIR/packaging/applesmc-als.modules-load.conf"

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
printf 'Low-light kernel support can be enabled from the plugin panel.\n'
