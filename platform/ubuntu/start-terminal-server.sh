#!/usr/bin/env bash
set -euo pipefail
base="$HOME/.local/share/caelestia-ubuntu"
source "$base/bin/environment.sh"
: "${HYPRLAND_INSTANCE_SIGNATURE:?Start the terminal server inside Caelestia/Hyprland.}"
group="caelestia-ubuntu-$HYPRLAND_INSTANCE_SIGNATURE"
# Keep caches warm without a workspace window. Watch this compositor's socket
# so the hidden process is cleaned up on logout, even in headless Kitty mode.
exec python3 - "$group" <<'PYTHON'
import os, socket, select, subprocess, sys, signal

def stop(signum, frame):
    raise SystemExit(0)
signal.signal(signal.SIGTERM, stop)
signal.signal(signal.SIGINT, stop)
sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
sock.connect(f"{os.environ['XDG_RUNTIME_DIR']}/hypr/{os.environ['HYPRLAND_INSTANCE_SIGNATURE']}/.socket2.sock")
process = subprocess.Popen([
    "kitty", "--single-instance", "--instance-group", sys.argv[1],
    "--start-as=hidden", "--class", "caelestia-terminal-server",
    "sh", "-c", "exec sleep infinity",
])
try:
    while process.poll() is None:
        if select.select([sock], [], [], 2)[0] and not sock.recv(65536):
            break
finally:
    sock.close()
    if process.poll() is None:
        process.terminate()
        try:
            process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait()
PYTHON
