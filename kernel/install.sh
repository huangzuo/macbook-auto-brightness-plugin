#!/usr/bin/env bash

set -euo pipefail

readonly VERSION=0.1.0
readonly PACKAGE=applesmc-als
readonly SOURCE_DIR="/usr/src/${PACKAGE}-${VERSION}"
readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

if (( EUID != 0 )); then
  printf 'Run this installer as root: sudo %q\n' "$0" >&2
  exit 1
fi

command -v dkms >/dev/null || {
  printf 'dkms is required. Install it before running this script.\n' >&2
  exit 1
}

install -d -m 0755 "$SOURCE_DIR"
install -m 0644 "$SCRIPT_DIR/drivers/hwmon/applesmc.c" "$SOURCE_DIR/applesmc-als.c"
install -m 0644 "$SCRIPT_DIR/packaging/Makefile" "$SOURCE_DIR/Makefile"
install -m 0644 "$SCRIPT_DIR/packaging/dkms.conf" "$SOURCE_DIR/dkms.conf"

dkms status -m "$PACKAGE" -v "$VERSION" | grep -q . || dkms add -m "$PACKAGE" -v "$VERSION"
dkms build -m "$PACKAGE" -v "$VERSION"
dkms install -m "$PACKAGE" -v "$VERSION" --force

install -Dm0644 "$SCRIPT_DIR/packaging/applesmc-als.modprobe.conf" \
  /etc/modprobe.d/applesmc-als.conf
install -Dm0644 "$SCRIPT_DIR/packaging/applesmc-als.modules-load.conf" \
  /etc/modules-load.d/applesmc-als.conf
depmod -a

printf 'Installed %s/%s for kernel %s.\n' "$PACKAGE" "$VERSION" "$(uname -r)"
