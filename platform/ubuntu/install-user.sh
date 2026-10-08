#!/usr/bin/env bash
set -euo pipefail
if (( EUID == 0 )); then echo 'Run as your normal user.' >&2; exit 1; fi
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
base="$HOME/.local/share/caelestia-ubuntu"
config="$HOME/.config/caelestia-ubuntu"
mkdir -p "$base/bin" "$config/hypr" "$config/caelestia" "$config/kitty" "$base/cache" "$base/state"
install -m755 "$here/environment.sh" "$base/bin/environment.sh"
install -m755 "$here/session.sh" "$base/bin/session"
install -m755 "$here/start-shell.sh" "$base/bin/start-shell"
install -m755 "$here/terminal.sh" "$base/bin/caelestia-terminal"
install -m755 "$here/start-terminal-server.sh" "$base/bin/start-terminal-server"
install -m644 "$here/caelestia-cli.py" "$base/bin/caelestia-cli.py"
if [[ ! -f "$config/caelestia/cli.json" ]]; then
 # Some upstream theme integrations change shared GTK settings, browser policies,
 # or every open PTY. Limit this separate session to its own Hyprland files.
 cat > "$config/caelestia/cli.json" <<'JSON'
{
 "theme": {
  "enableTerm":false,"enableHypr":true,"enableDiscord":false,
  "enableSpicetify":false,"enablePandora":false,"enableFuzzel":false,
  "enableBtop":false,"enableNvtop":false,"enableHtop":false,
  "enableGtk":false,"enableQt":false,"enableWarp":false,
  "enableChromium":false,"enableZed":false,"enableCava":false
 }
}
JSON
fi
if [[ ! -f "$config/hypr/hyprland.conf" ]]; then install -m644 "$here/hyprland.conf" "$config/hypr/hyprland.conf"; fi
if [[ ! -f "$config/caelestia/shell.json" ]]; then
 cat > "$config/caelestia/shell.json" <<'JSON'
{
 "services": {"clockFormat":"twelveHour","defaultPlayer":"Spotify"},
 "general": {
  "apps": {"terminal":["caelestia-terminal"],"audio":["pavucontrol"],"explorer":["nautilus"]},
  "idle": {"lockBeforeSleep":true,"timeouts":[
   {"timeout":300,"idleAction":"lock"},
   {"timeout":600,"idleAction":"dpms off","returnAction":"dpms on"},
   {"timeout":1800,"idleAction":["systemctl","suspend"]}
  ]}
 }
}
JSON
fi
if [[ ! -f "$config/kitty/kitty.conf" ]]; then
 cat > "$config/kitty/kitty.conf" <<'KITTY'
font_family CaskaydiaCove Nerd Font
font_size 11
background #101418
foreground #dee3e9
background_opacity 0.85
confirm_os_window_close 0
KITTY
fi
# The CLI wrapper blocks whole-dotfiles install/update in this independent session.
cat > "$base/bin/caelestia" <<'WRAPPER'
#!/usr/bin/env bash
set -euo pipefail
case ${1:-} in
 install|update) echo 'This Ubuntu session updates through its platform/ubuntu/build.sh, not the Arch dotfiles installer.' >&2; exit 2 ;;
esac
exec "$HOME/.local/share/caelestia-ubuntu/venv/bin/python" "$HOME/.local/share/caelestia-ubuntu/bin/caelestia-cli.py" "$@"
WRAPPER
chmod 755 "$base/bin/caelestia"
# Material Symbols is loaded only by this session's fontconfig configuration.
mkdir -p "$base/fonts"
if [[ ! -f "$base/fonts/MaterialSymbolsRounded.ttf" ]]; then
 curl -fL --max-time 180 --retry 2 \
  'https://raw.githubusercontent.com/google/material-design-icons/master/variablefont/MaterialSymbolsRounded%5BFILL,GRAD,opsz,wght%5D.ttf' \
  -o "$base/fonts/MaterialSymbolsRounded.ttf.download"
 mv "$base/fonts/MaterialSymbolsRounded.ttf.download" "$base/fonts/MaterialSymbolsRounded.ttf"
fi
python3 - "$base" <<'PY'
import sys,html
from pathlib import Path
p=Path(sys.argv[1])
(p/'fontconfig.xml').write_text('<?xml version="1.0"?><!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd"><fontconfig><include>/etc/fonts/fonts.conf</include><dir>'+html.escape(str(p/'fonts'))+'</dir></fontconfig>')
PY
printf '\nexport FONTCONFIG_FILE="$CAELESTIA_UBUNTU_ROOT/fontconfig.xml"\n' >> "$base/bin/environment.sh"
