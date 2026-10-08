#!/usr/bin/env bash
set -euo pipefail
if (( EUID != 0 )); then echo 'Run this registration step with sudo.' >&2; exit 1; fi
if [[ -z ${SUDO_USER:-} ]]; then echo 'Use sudo from your normal user account.' >&2; exit 1; fi
user_home=$(getent passwd "$SUDO_USER" | cut -d: -f6)
if [[ ! -f "$user_home/.local/share/caelestia-ubuntu/validated" ]]; then
 echo 'Run platform/ubuntu/check.sh successfully as your normal user first.' >&2; exit 1
fi
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# Only two new, uniquely named system files; existing sessions are untouched.
for file in /usr/local/bin/caelestia-session /usr/share/wayland-sessions/caelestia.desktop; do
 if [[ -e "$file" ]]; then cp -a "$file" "$file.backup-$(date +%Y%m%d-%H%M%S)"; fi
done
install -d /usr/local/bin /usr/share/wayland-sessions
cat > /usr/local/bin/caelestia-session <<'WRAPPER'
#!/bin/sh
exec "$HOME/.local/share/caelestia-ubuntu/bin/session"
WRAPPER
chmod 755 /usr/local/bin/caelestia-session
install -m644 "$here/caelestia.desktop" /usr/share/wayland-sessions/caelestia.desktop
echo 'Caelestia is now an additional login-screen session. No logout or reboot was performed.'
