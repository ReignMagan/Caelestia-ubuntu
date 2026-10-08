#!/usr/bin/env python3
"""Apply the shell palette to this session's Kitty and Ubuntu appearance."""
import json
import os
from pathlib import Path
import signal
import subprocess


def sync_theme():
    config = Path(os.environ["XDG_CONFIG_HOME"])
    state = Path(os.environ["XDG_STATE_HOME"]) / "caelestia"
    scheme = json.loads((state / "scheme.json").read_text())
    colours = scheme["colours"]
    mode = scheme["mode"]
    palette = {
        "background": colours["surface"], "foreground": colours["onSurface"],
        "cursor": colours["secondary"], "cursor_text_color": colours["surface"],
        "selection_background": colours["secondary"],
        "selection_foreground": colours["onSecondary"],
        **{f"color{i}": colours[f"term{i}"] for i in range(16)},
    }
    target = config / "kitty/theme.conf"
    target.parent.mkdir(parents=True, exist_ok=True)
    temporary = target.with_suffix(".tmp")
    temporary.write_text("".join(f"{key} #{value}\n" for key, value in palette.items()))
    temporary.replace(target)
    # Reload only Kitty processes belonging to this isolated configuration and
    # compositor, including its hidden warm server. Never write into every PTY.
    instance = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE")
    if instance:
        for process in Path("/proc").glob("[0-9]*"):
            try:
                if (process / "comm").read_text().strip() != "kitty":
                    continue
                environment = (process / "environ").read_bytes().split(b"\0")
                if (f"XDG_CONFIG_HOME={config}".encode() in environment
                        and f"HYPRLAND_INSTANCE_SIGNATURE={instance}".encode() in environment):
                    os.kill(int(process.name), signal.SIGUSR1)
            except (OSError, ValueError):
                pass
        for setting, colour in (("col.active_border", "primary"),
                                ("col.inactive_border", "outlineVariant")):
            subprocess.run(["hyprctl", "keyword", f"general:{setting}",
                            f"rgba({colours[colour]}ff)"], capture_output=True, timeout=3)
    for key, value in (("color-scheme", f"prefer-{mode}"),
                       ("gtk-theme", "Yaru-dark" if mode == "dark" else "Yaru")):
        subprocess.run(["gsettings", "set", "org.gnome.desktop.interface", key, value],
                       env={**os.environ, "XDG_CONFIG_HOME": str(Path.home() / ".config")},
                       capture_output=True, timeout=3, check=True)


if __name__ == "__main__":
    sync_theme()
