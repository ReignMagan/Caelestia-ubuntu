#!/usr/bin/env bash
set -euo pipefail
base="$HOME/.local/share/caelestia-ubuntu"
source "$base/bin/environment.sh"
mkdir -p "$XDG_CACHE_HOME" "$XDG_STATE_HOME"
if [[ -f "$XDG_STATE_HOME/caelestia/scheme.json" ]]; then
 "$base/bin/sync-theme.py" || true
fi
# Shell colour templates stay in the private configuration directory.
if [[ ! -e "$XDG_STATE_HOME/caelestia/wallpaper/path.txt" ]]; then
 caelestia wallpaper -f "$XDG_CONFIG_HOME/quickshell/caelestia/assets/wallpaper.webp" || true
fi
exec python3 "$base/bin/shell-supervisor.py" > "$XDG_CACHE_HOME/shell.log" 2>&1
