#!/usr/bin/env bash
# Source only inside the independent Caelestia session.
export CAELESTIA_UBUNTU_SESSION=1
export CAELESTIA_UBUNTU_ROOT="$HOME/.local/share/caelestia-ubuntu"
export CAELESTIA_LIB_DIR="$CAELESTIA_UBUNTU_ROOT/runtime/lib/caelestia"
export XDG_CONFIG_HOME="$HOME/.config/caelestia-ubuntu"
export XDG_CACHE_HOME="$CAELESTIA_UBUNTU_ROOT/cache"
export XDG_STATE_HOME="$CAELESTIA_UBUNTU_ROOT/state"
# Keep system/user application discovery in the normal XDG data directories.
export XDG_DATA_DIRS="${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
# Display-manager sessions may skip Ubuntu's Snap/Flatpak profile scripts.
for caelestia_data_dir in /var/lib/snapd/desktop /var/lib/flatpak/exports/share "$HOME/.local/share/flatpak/exports/share"; do
    if [[ -d "$caelestia_data_dir" && ":$XDG_DATA_DIRS:" != *":$caelestia_data_dir:"* ]]; then
        XDG_DATA_DIRS="$XDG_DATA_DIRS:$caelestia_data_dir"
    fi
done
unset caelestia_data_dir
export PATH="$CAELESTIA_UBUNTU_ROOT/bin:$CAELESTIA_UBUNTU_ROOT/runtime/bin:$CAELESTIA_UBUNTU_ROOT/venv/bin:$PATH"
export QML_IMPORT_PATH="$CAELESTIA_UBUNTU_ROOT/runtime/lib/qt6/qml${QML_IMPORT_PATH:+:$QML_IMPORT_PATH}"
export LD_LIBRARY_PATH="$CAELESTIA_UBUNTU_ROOT/runtime/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export QT_QUICK_CONTROLS_STYLE=Material
