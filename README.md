# Caelestia-ubuntu

An Ubuntu port of [Caelestia Shell](https://github.com/caelestia-dots/shell),
built on Quickshell and Hyprland. It adds a separate **Caelestia** desktop session
at login, with its own shell runtime and configuration.

Your existing Ubuntu, GNOME, and Hyprland sessions remain available. The installer
does not replace the display manager, edit system PAM files, install Arch
packages, or replace the system Quickshell executable.

> **Experimental Ubuntu port:** built and startup-tested on Ubuntu **26.04 LTS**
> with Qt **6.10** and Hyprland **0.53.3**, on x86_64. Ubuntu 22.04 and 24.04 are
> not supported by these instructions. Other releases and architectures have not
> been tested. Password unlocking and suspend/resume still need testing in a
> real Caelestia login session.

## What you get

- Caelestia's bar, launcher, dashboard, notifications, media controls, and lock screen.
- A separate **Caelestia** entry in your existing login screen's session selector.
- Ubuntu authentication and Qt 6.10 compatibility fixes.
- Private Quickshell, native plugins, CLI virtualenv, and icon font.
- Existing desktop configurations kept separate from this port.

This is a shell/session port, not the full upstream Arch dotfiles installation.
The default appearance follows Caelestia; your existing rice is not imported.

## Requirements

Use a normal user account on Ubuntu 26.04 Desktop with:

- A working Wayland desktop and a display manager that lists Wayland sessions
  (tested with SDDM; other display managers have not been tested).
- Internet access, sudo access for Ubuntu packages and login registration,
  and several GB of free disk space for source builds.
- Working graphics drivers. The installer does not install or replace GPU drivers.

The dependency step installs Hyprland, Kitty, required desktop tools, and build
libraries from Ubuntu repositories. It does not install or replace your display
manager. Build jobs default to **2**; allow time for the initial compilation.

## Installation

### 1. Get the Ubuntu port

Open a terminal in your existing Wayland desktop:

```bash
sudo apt update
sudo apt install --no-install-recommends git

git clone --branch ubuntu-session https://github.com/ReignMagan/Caelestia-ubuntu.git
cd Caelestia-ubuntu
```

### 2. Install dependencies and build

```bash
bash platform/ubuntu/install-dependencies.sh
bash platform/ubuntu/build.sh
```

Enter your sudo password when the dependency installer requests it. **Do not
run the build script with sudo.** Runtime libraries are installed in your home
directory. The dependency installer refuses package removals and does not upgrade
already-installed packages; resolve any reported package/version conflict before
continuing.

For a lower-memory build, use one job:

```bash
CAELESTIA_BUILD_JOBS=1 bash platform/ubuntu/build.sh
```

### 3. Test before registering the session

```bash
bash platform/ubuntu/check.sh
```

Run this from an existing **Wayland** desktop. It opens a temporary nested
Hyprland window, verifies the shell loads, and closes automatically after about
25 seconds. It does not switch or end your active desktop. Continue only after
it reports that the startup checks passed.

This startup check does not verify your password, suspend/resume, or all hardware
controls. It saves logs under `~/.local/share/caelestia-ubuntu/cache/`.

### 4. Add the login option

```bash
sudo bash platform/ubuntu/register-session.sh
```

Save your work and log out **when you are ready**. At the login screen, open the
session selector, choose **Caelestia**, then sign in. Locking an existing session
will not switch desktops. The installer does not log you out or reboot.

If the new session fails, return to your existing Ubuntu/GNOME/Hyprland session
and inspect `~/.local/share/caelestia-ubuntu/cache/shell.log`.

## Shortcuts

| Shortcut | Action |
| --- | --- |
| Super + Enter or T | Terminal |
| Super + Space | Launcher |
| Super + D | Dashboard |
| Super + N | Notifications sidebar |
| Super + L | Lock screen |
| Super + Shift + E | Session/power menu |
| Super + Ctrl + comma | Shell settings |
| Super + F | Fullscreen |
| Super + W or Q | Close window |
| Super + 1–5 | Change workspace |
| Super + Shift + 1–5 | Move window to workspace |

Volume and brightness keys are configured. Hardware support depends on your
Ubuntu audio and backlight setup.

## Customize

Only edit the separate configuration:

| File | Purpose |
| --- | --- |
| `~/.config/caelestia-ubuntu/caelestia/shell.json` | Shell settings |
| `~/.config/caelestia-ubuntu/hypr/hyprland.conf` | Hyprland and keybinds |
| `~/.config/caelestia-ubuntu/kitty/kitty.conf` | Terminal appearance |
| `~/.config/caelestia-ubuntu/caelestia/cli.json` | CLI/theme integrations |

Initial settings use a 12-hour clock. Optional Nerd Fonts can be selected in
Kitty; fonts already installed on your system are available to this session.
The CLI's shared GTK, browser-policy, application-data, and open-terminal theme
integrations are disabled to keep other desktop sessions separate. Avoid enabling
those integrations unless you intend their effects outside this session.

## Update

Return to your other desktop session before updating the installed Caelestia shell:

```bash
cd Caelestia-ubuntu
git pull --ff-only
bash platform/ubuntu/install-dependencies.sh
bash platform/ubuntu/build.sh
bash platform/ubuntu/check.sh
```

The build preserves existing Hyprland, Kitty, and shell settings. Installed QML
files are replaced, so keep custom source changes in your own Git branch.
`caelestia install` and `caelestia update` are blocked in this session because
those commands belong to the upstream full-dotfiles installer.

## Remove the login option

From the cloned repository:

```bash
sudo bash platform/ubuntu/unregister-session.sh
```

This disables the Caelestia entry and leaves your other sessions available.
Its private runtime/configuration and Ubuntu dependencies remain installed;
there is no automatic package removal. You can keep these files for a later retry.

## Development and credits

See [the platform guide](platform/ubuntu/README.md) for the isolation paths,
validation limits, and port implementation. Dependency source revisions are
pinned in `platform/ubuntu/runtime-lock.json` and `build.sh`.

Caelestia Shell and its design are by
[caelestia-dots and upstream contributors](https://github.com/caelestia-dots/shell).
This repository is a fork providing Ubuntu integration; it is not an official
Ubuntu release from upstream. The upstream [license](LICENSE) and
[original documentation](README.upstream.md) are retained.
