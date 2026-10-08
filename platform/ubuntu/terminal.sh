#!/usr/bin/env bash
set -euo pipefail
base="$HOME/.local/share/caelestia-ubuntu"
source "$base/bin/environment.sh"
# Keep sharing within this compositor session, never another logged-in desktop.
group="caelestia-ubuntu-${HYPRLAND_INSTANCE_SIGNATURE:-${WAYLAND_DISPLAY:-default}}"
exec kitty --single-instance --instance-group "$group" "$@"
