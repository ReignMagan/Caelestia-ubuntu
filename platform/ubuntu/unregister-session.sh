#!/usr/bin/env bash
set -euo pipefail
if (( EUID != 0 )); then echo 'Run with sudo.' >&2; exit 1; fi
file=/usr/share/wayland-sessions/caelestia.desktop
if [[ -f "$file" ]]; then mv "$file" "$file.disabled-$(date +%Y%m%d-%H%M%S)"; fi
echo 'Caelestia login option disabled. Existing sessions and user files are unchanged.'
