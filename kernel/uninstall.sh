#!/usr/bin/env bash

set -euo pipefail

readonly VERSION=0.1.0
readonly PACKAGE=applesmc-als
readonly SOURCE_DIR="/usr/src/${PACKAGE}-${VERSION}"

if (( EUID != 0 )); then
  printf 'Run this uninstaller as root: sudo %q\n' "$0" >&2
  exit 1
fi

dkms remove -m "$PACKAGE" -v "$VERSION" --all 2>/dev/null || true
rm -f /etc/modprobe.d/applesmc-als.conf
rm -f /etc/modules-load.d/applesmc-als.conf
rm -rf -- "$SOURCE_DIR"
depmod -a

if lsmod | grep -q '^applesmc_als '; then
  rmmod applesmc_als
  modprobe applesmc
fi

printf 'Removed %s/%s and restored the stock applesmc module.\n' "$PACKAGE" "$VERSION"
