# Independent Caelestia session for Ubuntu

This port targets Ubuntu 26.04 with Qt 6.10. The dependency installer includes
Hyprland and desktop tools; an existing Wayland desktop is needed for validation.
For clone-to-login instructions, start with [the main README](../../README.md).
It adds a **Caelestia** entry to the display manager alongside Ubuntu, GNOME, and
Hyprland. The session uses its own config and runtime; it does not install the
Arch dotfiles or replace the existing Quickshell executable.

## Install

From this repository, as your normal user:

```sh
bash platform/ubuntu/install-dependencies.sh
bash platform/ubuntu/build.sh
bash platform/ubuntu/check.sh
sudo bash platform/ubuntu/register-session.sh
```

The package step uses Ubuntu's configured package repositories, refuses package
removals, and does not upgrade installed packages. Build steps use two jobs by
default (`CAELESTIA_BUILD_JOBS` can override this) and install without sudo.
The registration step creates only `/usr/local/bin/caelestia-session` and
`/usr/share/wayland-sessions/caelestia.desktop`; pre-existing files at those two
paths are backed up.

Select **Caelestia** from the session selector at login. This does not change the
session of an already logged-in, locked desktop. No display-manager restart,
logout, or reboot is performed by the installer.

## Isolation

- Runtime, build artifacts, private libraries, and CLI virtualenv:
  `~/.local/share/caelestia-ubuntu/`.
- Hyprland, Kitty, Caelestia shell settings, and generated theme configs:
  `~/.config/caelestia-ubuntu/`.
- Caelestia's Git Quickshell is used only inside this session. `/usr/bin/quickshell`
  and `~/.config/quickshell/desktop` remain unchanged.
- `XDG_DATA_HOME` remains normal so the launcher can discover installed apps.
- The session wrapper refuses `caelestia install` and `caelestia update`, because
  the whole-dotfiles installer is outside this Ubuntu session's scope.
- CLI theme integrations that alter shared GTK settings, browser policies,
  application data, or other open terminals are disabled for this session.
- Ubuntu password authentication uses `/etc/pam.d/common-auth` only when
  `CAELESTIA_UBUNTU_SESSION=1`; the upstream bundled PAM stack is unchanged on
  other platforms. No system PAM files are written.
- Material Symbols is loaded through session-specific fontconfig, not a global
  font replacement.

## Shortcuts

| Shortcut | Action |
| --- | --- |
| Super + Return / T | Terminal |
| Super + Space | Launcher |
| Super + D | Dashboard |
| Super + N | Notifications sidebar |
| Super + L | Lock |
| Super + Shift + E | Session/power menu |
| Super + Ctrl + comma | Shell settings |
| Super + F | Fullscreen |
| Super + W / Q | Close window |
| Super + 1–5 | Workspace |
| Super + Shift + 1–5 | Move window to workspace |

Media and brightness keys retain their normal functions.

## Contribution scope

The QML changes select Ubuntu PAM authentication and adapt decimal settings,
shadow radii, and a lock-screen identifier for Qt 6.10 compatibility.
A CMake include-path fix also supports libcava installed under a private prefix.
The `platform/ubuntu/` scripts provide a reproducible, isolated installation and
session registration. Runtime dependency revisions are pinned in `build.sh`;
these need deliberate review when updating upstream. This is an Ubuntu 26.04
port, not a claim of support for older releases with older Qt.

The automated check verifies config syntax, library linkage, and QML startup on
a private bus in a temporary nested Wayland window. Run the check from your
existing Wayland desktop; the test closes automatically. Real password unlocking, suspend/resume, Bluetooth hardware, and
display-manager session entry still need an actual-session smoke test.

## Remove the login option

```sh
sudo bash platform/ubuntu/unregister-session.sh
```

This disables only the new Caelestia entry and preserves its files and runtime.
Choose your existing Hyprland or Ubuntu/GNOME session to return to the prior
setup.
