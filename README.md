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

## Install

Install the user service and Omarchy plugin:

```sh
./install.sh
```

For the low-light fallback, install the kernel module through DKMS:

```sh
sudo ./kernel/install.sh
```

The kernel installer blacklists the stock `applesmc` module and configures the
patched `applesmc_als` module to load at boot. DKMS rebuilds it for kernel
updates. The patch was built and tested against Arch Linux kernel
`7.1.8-arch1-3`; later kernel APIs may require adjustments.

## Controls

The bar widget displays measured lux, current brightness, and target
brightness. Its panel can enable or pause automatic control, resume after a
manual override, select Dim/Balanced/Bright presets, and tune offset, response
speed, and smoothing.

The controller is also available from a terminal:

```sh
auto-brightnessctl status
auto-brightnessctl enable
auto-brightnessctl disable
auto-brightnessctl preset balanced
```

## Remove

Remove the plugin and user service while preserving preferences:

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

The project is licensed under GPL-2.0-only. The patched driver retains its
original Linux kernel copyright notices.
