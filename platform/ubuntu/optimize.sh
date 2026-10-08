#!/usr/bin/env bash
# Explicit migration for existing users; build.sh preserves their config files.
set -euo pipefail
if (( EUID == 0 )); then echo 'Run as your normal user, without sudo.' >&2; exit 1; fi
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
base="$HOME/.local/share/caelestia-ubuntu"
config="$HOME/.config/caelestia-ubuntu"
[[ -f "$base/bin/environment.sh" && -f "$config/hypr/hyprland.conf" ]] || {
 echo 'Install the separate Caelestia session first.' >&2; exit 1;
}
python3 - "$config" "$here/hyprland.conf" <<'PY'
from pathlib import Path
import sys,re,shutil,datetime,subprocess,json
config=Path(sys.argv[1]); template=Path(sys.argv[2]).read_text()
p=config/'hypr/hyprland.conf'; original=p.read_text()
if '$terminal = kitty' not in original and '$terminal = caelestia-terminal' not in original:
 raise SystemExit('Custom terminal binding detected. Review performance settings manually; config was not changed.')
# These blocks are supplied by this port and have no nested sections.
animations=re.search(r'^animations \{\n.*?^\}',template,re.M|re.S).group()
updated=re.sub(r'^animations \{\n.*?^\}',lambda _:animations,original,count=1,flags=re.M|re.S)
updated=updated.replace('$terminal = kitty','$terminal = caelestia-terminal')
server='exec-once = ~/.local/share/caelestia-ubuntu/bin/start-terminal-server'
if server not in updated: updated=updated.replace('exec-once = ~/.local/share/caelestia-ubuntu/bin/start-shell','exec-once = ~/.local/share/caelestia-ubuntu/bin/start-shell\n'+server)
updated=updated.replace('  size = 5\n  passes = 2','  size = 4\n  passes = 1')
stamp=datetime.datetime.now().strftime('%Y%m%d-%H%M%S-%f')
backup=config/'performance-backups'/stamp
backup.mkdir(parents=True)
shutil.copy2(p,backup/'hyprland.conf')
settings=config/'caelestia/shell.json'
obj=json.loads(settings.read_text())
terminal=obj.setdefault('general',{}).setdefault('apps',{}).get('terminal')
if terminal in (None,['kitty'],['caelestia-terminal']):
 shutil.copy2(settings,backup/'shell.json')
 obj['general']['apps']['terminal']=['caelestia-terminal']
else:
 print('Keeping custom launcher terminal command:',terminal)
pending=p.with_name('performance-preview.conf')
pending.write_text(updated)
try:
 subprocess.run(['/usr/bin/Hyprland','--verify-config','--config',str(pending)],check=True)
finally:
 pending.unlink(missing_ok=True)
p.write_text(updated)
settings.write_text(json.dumps(obj,indent=2)+'\n')
print('Performance config installed. Backup:',backup)
PY
install -m755 "$here/terminal.sh" "$base/bin/caelestia-terminal"
install -m755 "$here/start-terminal-server.sh" "$base/bin/start-terminal-server"
echo 'Settings will apply at your next Caelestia login. No active session was reloaded.'
