# MacBook automatic brightness for Omarchy

Automatic display brightness for an Intel MacBook running Omarchy, with a bar
widget for status and controls. This source bundle contains:

- the Omarchy Shell plugin (`manifest.json` and `Panel.qml`);
- the automatic-brightness daemon and controller;
- the systemd user service and example configuration.

## Current sensor approach

The daemon reads the standard `acpi-als` IIO illuminance interface supplied by
the stock kernel. It does not install, replace, blacklist, or modify any kernel
driver.

## Requirements

This plugin targets Intel MacBooks with an ACPI ambient-light sensor. It also
requires `brightnessctl`, which is included with Omarchy.

## Install as an Omarchy plugin

Once this repository is published, install it with Omarchy's standard plugin
manager. Replace the example URL with the public Git repository URL:

```sh
REPOSITORY_URL="https://github.com/huangzuo/macbook-auto-brightness-plugin.git"
omarchy plugin add "$REPOSITORY_URL" --yes
omarchy plugin enable hz.auto-brightness --section right
```

Omarchy intentionally does not execute install hooks from plugins. On first
open, the panel detects the missing backend and offers **Set up backend**. This
installs and starts the user service without modifying the Git-managed plugin
checkout. The same setup can be performed from a terminal:

```sh
~/.config/omarchy/plugins/hz.auto-brightness/install.sh --backend-only
```

To install directly from a local checkout instead, run:

```sh
./install.sh
```

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

## Source layout

```text
Panel.qml, manifest.json  Omarchy Shell plugin
bin/                      brightness daemon and command-line controller
config/                   example preferences
systemd/                  user service
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

The project is licensed under GPL-2.0-only.
