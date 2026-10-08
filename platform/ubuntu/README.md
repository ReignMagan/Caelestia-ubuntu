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
- App discovery includes Ubuntu Snap and installed Flatpak export directories,
  including Spotify's Snap desktop entry, even when login profile scripts are skipped.
- The session wrapper refuses `caelestia install` and `caelestia update`, because
  the whole-dotfiles installer is outside this Ubuntu session's scope.
- A theme hook generates Kitty's palette, reloads only this session's Kitty
  processes, and updates window borders. Theme changes need no polling daemon.
- The shell launcher recovers unexpected Quickshell crashes with a short backoff
  and a retry limit. It exits on intentional shell shutdown or compositor logout.
- The Proxy status icon opens a hostname/port panel with HTTP/HTTPS and SOCKS
  options. Save and enable applies the address to Ubuntu's system proxy; Off
  retains it for later. Settings are shared with the account's other desktops.
  Apps must support the system proxy; this does not create a VPN or a tunnel.
  Status reflects the configured setting, not a connection or anonymity test.
  A single sleeping dconf subscription tracks changes without polling servers.
  Test connection makes one explicit request through the saved proxy without
  changing the switch. For Brave, a per-user launcher enables Chromium's GNOME
  proxy-settings subscription within Hyprland. Close and reopen an already
  running Brave once after installation; subsequent switches are live.
- Ubuntu's standard GTK light/dark preference and Yaru variant follow the shell.
  These two appearance preferences are shared with GNOME on the same account.
  The session's dconf directory links to the account's normal database so GTK
  clients agree with the D-Bus settings service; any old private database is backed up.
  Apps with custom themes may need their own system-theme setting.
- Upstream integrations that change browser policies, application data, or
  unrelated terminals remain disabled.
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
