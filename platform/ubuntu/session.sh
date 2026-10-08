#!/usr/bin/env bash
set -euo pipefail
base="$HOME/.local/share/caelestia-ubuntu"
source "$base/bin/environment.sh"
export XDG_CURRENT_DESKTOP=Hyprland
export XDG_SESSION_DESKTOP=Caelestia
export XDG_SESSION_TYPE=wayland
# The existing current session is never stopped by this launcher.
exec /usr/bin/start-hyprland -- --config "$XDG_CONFIG_HOME/hypr/hyprland.conf"
