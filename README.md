# MacBook automatic brightness for Omarchy

Automatic display brightness for an Intel MacBook running Omarchy, with a bar
widget for status and controls. This source bundle contains everything used on
the tested MacBookPro11,1:

- the Omarchy Shell plugin (`manifest.json` and `Panel.qml`);
- the automatic-brightness daemon and controller;
- the systemd user service and example configuration;
- the experimental `applesmc` low-light kernel patch;
- out-of-tree and DKMS build files, installation scripts, and rollback tools;
- an apply-ready Linux kernel patch in `kernel/dist/`.

## Current sensor approach

The standard ACPI ALS value is preferred whenever it is above zero. When Apple
rounds that value to zero, the daemon reads the patched `light_raw` attribute
and estimates low light from ALV0 channel 0. The default MacBookPro11,1
calibration is approximately 14 high-gain counts per lux.

The kernel patch preserves the existing `light` interface and adds:

- `light_millilux`: the complete FP18.14 room-light value in millilux;
- `light_raw`: `valid high_gain channel0 channel1 room_lux_fp18_14`.

## Requirements

This plugin targets Intel MacBooks with an ACPI ambient-light sensor. It also
requires `brightnessctl`, which is included with Omarchy.

## Install as an Omarchy plugin

Once this repository is published, install it with Omarchy's standard plugin
manager. Replace the example URL with the public Git repository URL:

```sh
REPOSITORY_URL="https://github.com/YOUR-NAME/macbook-auto-brightness.git"
omarchy plugin add "$REPOSITORY_URL" --yes
~/.config/omarchy/plugins/hz.auto-brightness/install.sh --backend-only
omarchy plugin enable hz.auto-brightness --section right
```

Omarchy intentionally does not execute install hooks from plugins. The explicit
backend step installs and starts the user service; it does not recopy or modify
the Git-managed plugin checkout.

To install directly from a local checkout instead, run:

```sh
./install.sh
```

The panel includes a **Low-light sensor** toggle. Enabling it opens the system
authorization dialog and installs the bundled kernel module through DKMS.
Restart after enabling it so the patched sensor driver replaces the stock
driver. The same toggle removes the module and restores the stock driver.

The terminal equivalents are:

```sh
auto-brightnessctl low-light enable
auto-brightnessctl low-light disable
```

The kernel installer blacklists the stock `applesmc` module and configures the
patched `applesmc_als` module to load at boot. DKMS rebuilds it for kernel
updates. The patch was built and tested against Arch Linux kernel
`7.1.8-arch1-3`; later kernel APIs may require adjustments.

## Controls

The bar widget displays measured lux, current brightness, and target
brightness. Its panel can enable or pause automatic control, enable or disable
the low-light sensor driver, resume after a manual override, select
Dim/Balanced/Bright presets, and tune offset, response speed, and smoothing.

The controller is also available from a terminal:

```sh
auto-brightnessctl status
auto-brightnessctl enable
auto-brightnessctl disable
auto-brightnessctl low-light enable
auto-brightnessctl low-light disable
auto-brightnessctl preset balanced
```

## Remove

For a plugin installed from Git, remove the backend before asking Omarchy to
remove the checkout:

```sh
~/.config/omarchy/plugins/hz.auto-brightness/uninstall.sh --backend-only
omarchy plugin remove hz.auto-brightness
```

For a local-checkout installation, remove both pieces with:

```sh
./uninstall.sh
```

Restore the stock kernel driver:

```sh
sudo ./kernel/uninstall.sh
```

## Source layout

```text
Panel.qml, manifest.json  Omarchy Shell plugin
bin/                      brightness daemon and command-line controller
config/                   example preferences
systemd/                  user service
kernel/drivers/           patched Linux applesmc source
kernel/Documentation/     new sysfs ABI documentation
kernel/out-of-tree/       test-module build wrapper
kernel/packaging/         DKMS packaging
kernel/dist/              standalone kernel patch
```

## Validate

The repository root is the plugin root. Before publishing or submitting it to a
plugin directory, validate the manifest and QML:

```sh
omarchy plugin validate .
/usr/lib/qt6/bin/qmllint -I "$OMARCHY_PATH/shell" Panel.qml
```

The plugin uses the permanent third-party ID `hz.auto-brightness`; keep the
directory name, manifest ID, and QML `moduleName` aligned if it is ever renamed.

The project is licensed under GPL-2.0-only. The patched driver retains its
original Linux kernel copyright notices.
