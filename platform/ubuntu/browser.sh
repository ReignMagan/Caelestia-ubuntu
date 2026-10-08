#!/usr/bin/env bash
set -euo pipefail
# Chromium only subscribes to GNOME's live proxy settings when it detects GNOME.
# Scope that detection to Brave, preserving Hyprland's actual desktop environment.
export XDG_CURRENT_DESKTOP=GNOME
export XDG_CONFIG_HOME="$HOME/.config"
exec /usr/bin/brave-browser-stable "$@"
