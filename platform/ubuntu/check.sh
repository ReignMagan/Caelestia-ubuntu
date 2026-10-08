#!/usr/bin/env bash
set -euo pipefail
base="$HOME/.local/share/caelestia-ubuntu"
source "$base/bin/environment.sh"
/usr/bin/Hyprland --verify-config --config "$XDG_CONFIG_HOME/hypr/hyprland.conf"
qs --version
caelestia --version
if ldd "$base/runtime/bin/quickshell" | grep -q 'not found'; then
 echo 'Quickshell has unresolved runtime libraries.' >&2; exit 1
fi
if [[ -z ${WAYLAND_DISPLAY:-} ]]; then
 echo 'Run validation from an existing Wayland desktop; the test opens a temporary nested window.' >&2
 exit 1
fi
# A private bus and nested compositor prevent taking over the active desktop.
# Invalid explicit DRM device selection prevents opening the physical display.
# This test has no DBus activation-environment updates or log-out actions.
log="$base/cache/startup-check.log"
: > "$log"
cat > "$base/cache/startup-check-hyprland.conf" <<CONFIG
monitor = , 1280x800@60, auto, 1
exec-once = timeout 20s qs -c caelestia -n --no-color > "$log" 2>&1
exec-once = sh -c 'sleep 12; grim "$base/cache/startup-preview.png"'
general {
 border_size = 0
}
misc {
 disable_hyprland_logo = true
 disable_splash_rendering = true
}
CONFIG
set +e
env -u HYPRLAND_INSTANCE_SIGNATURE -u DISPLAY AQ_DRM_DEVICES=/dev/null QT_QPA_PLATFORM=wayland \
 dbus-run-session -- timeout 25s Hyprland --config "$base/cache/startup-check-hyprland.conf" \
 > "$base/cache/startup-compositor.log" 2>&1
status=$?
set -e
if [[ $status != 124 ]] || ! grep -q 'Configuration Loaded' "$log"; then
 cat "$log" >&2
 echo 'Shell startup validation failed; do not register the login session.' >&2
 exit 1
fi
if grep -Eq 'Failed to load configuration|module .* is not installed|Type .* unavailable|TypeError|ReferenceError|error while loading shared libraries' "$log"; then
 cat "$log" >&2; exit 1
fi
touch "$base/validated"
echo 'Config, runtime linkage, and nested Wayland QML startup checks passed.'
