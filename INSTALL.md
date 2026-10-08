# Install Caelestia on Ubuntu: step-by-step guide

This guide downloads and builds **Caelestia-ubuntu**, then adds **Caelestia** as a
separate desktop choice at login. Your existing desktop sessions stay available.

**Supported target:** Ubuntu **26.04 LTS**, x86_64, with a working Wayland desktop.
The port has been built and startup-tested with Qt 6.10, Hyprland 0.53.3, and SDDM.
It is experimental: real-session password unlocking, suspend/resume, and other
login managers still need testing. Ubuntu 22.04 and 24.04 are not supported by
this installer.

Run each step in order. If a command reports an error, resolve it before moving
to the next step. You do not need a GitHub account to download this public fork.

## 1. Open a terminal and check your Ubuntu version

In Ubuntu, open the Terminal app (normally **Ctrl + Alt + T**). Run:

```bash
cat /etc/os-release
uname -m
printf '%s\n' "$XDG_SESSION_TYPE"
```

Check these results:

- `/etc/os-release` should show `ID=ubuntu` and `VERSION_ID="26.04"`.
- `uname -m` should show `x86_64` for the tested architecture.
- The session type should show `wayland`.

If the session type is `x11`, save your work and sign into an existing Wayland
session before the validation step. The installer does not enable Wayland or
change graphics drivers for you.

## 2. Install Git

Git downloads the project from GitHub. Run:

```bash
sudo apt update
sudo apt install --no-install-recommends git
```

Enter your Ubuntu password when prompted. Password characters do not appear in
the terminal while you type. Press Enter after typing it. If APT asks whether to
continue, review its package summary, then enter `Y` to proceed.

## 3. Download Caelestia-ubuntu

These commands put the project in your Downloads folder:

```bash
mkdir -p "$HOME/Downloads"
cd "$HOME/Downloads"
git clone --branch ubuntu-session https://github.com/ReignMagan/Caelestia-ubuntu.git
cd Caelestia-ubuntu
```

Check that you are in the right folder:

```bash
pwd
ls platform/ubuntu
```

The path should end in `/Downloads/Caelestia-ubuntu`. The file listing should
include `install-dependencies.sh`, `build.sh`, `check.sh`, and
`register-session.sh`.

Keep this folder: you will use it to update the port or disable its login entry.
Use Git clone rather than GitHub's ZIP download; the build uses Git metadata.

## 4. Install Ubuntu dependencies

From that same project folder, run:

```bash
bash platform/ubuntu/install-dependencies.sh
```

Enter your sudo password if requested. This installs Hyprland, Kitty, desktop
tools, and build dependencies from Ubuntu's package repositories. It may install
many development packages and requires several GB of free space for the later
source build.

The script refuses package removals and does not upgrade packages that are
already installed. Wait until it finishes and returns to your terminal prompt.
If dependency resolution fails, stop here; do not bypass it by installing Arch
packages or running the full upstream dotfiles installer.

## 5. Build the shell

Run this as your **normal user**, without sudo:

```bash
bash platform/ubuntu/build.sh
```

The script downloads pinned dependency sources and builds a private Quickshell
runtime, Caelestia plugins, and the shell. It also creates a private Python
virtualenv and installs the icon font.

Compilation can take a while. Keep the terminal open and wait for:

```text
Built the independent Caelestia runtime. Run the validation before registering its login session.
```

The default is two build jobs. For a lower-memory build, use this command
**instead** of the command above:

```bash
CAELESTIA_BUILD_JOBS=1 bash platform/ubuntu/build.sh
```

The build installs under `~/.local/share/caelestia-ubuntu/` and writes separate
settings under `~/.config/caelestia-ubuntu/`.

## 6. Test startup in a temporary window

While still in your existing Wayland desktop, run:

```bash
bash platform/ubuntu/check.sh
```

A temporary nested Hyprland window will appear. This is a test desktop inside a
window, not a switch away from your current desktop. It closes automatically
after about 25 seconds.

Continue only when the terminal reports:

```text
Config, runtime linkage, and nested Wayland QML startup checks passed.
```

The test checks configuration syntax, native library linkage, and QML startup.
It does not test your password, suspend/resume, or every hardware feature.

## 7. Add Caelestia to the login screen

After the test succeeds, run:

```bash
sudo bash platform/ubuntu/register-session.sh
```

Enter your sudo password when requested. The script creates:

```text
/usr/local/bin/caelestia-session
/usr/share/wayland-sessions/caelestia.desktop
```

It leaves the existing desktop entries in place and does not restart the login
manager, log you out, or reboot.

## 8. Sign into Caelestia

1. Save your work and close documents you are editing.
2. Log out through your current desktop's session menu.
3. At the login screen, open the **session selector**. Its location depends on
   your login manager; look for a desktop/session menu or a gear icon.
4. Select **Caelestia**.
5. Enter your normal Ubuntu credentials and sign in.

Locking your existing desktop will not change the session. You must log out to
choose a different desktop.

If **Caelestia** is missing, sign back into your existing desktop and check:

```bash
cat /usr/share/wayland-sessions/caelestia.desktop
```

If that file is missing, repeat step 7. If it exists but the selector does not
show it, your display manager's Wayland-session discovery needs investigation;
do not replace your login manager just to work around this.

## 9. Try the main shortcuts

**Super** is normally the Windows-logo key on your keyboard.

| Shortcut | Action |
| --- | --- |
| Super + T or Enter | Open Kitty terminal |
| Super + Space | Open launcher |
| Super + D | Open dashboard |
| Super + N | Open notifications sidebar |
| Super + Ctrl + comma | Open shell settings |
| Super + F | Toggle fullscreen |
| Super + W or Q | Close the active window |
| Super + 1–5 | Switch workspace |
| Super + Shift + 1–5 | Move a window to a workspace |
| Super + Shift + E | Open the session/power menu |
| Super + L | Lock the screen |

Volume and brightness keys are configured; their behaviour depends on the
Ubuntu hardware/audio setup. Before relying on this experimental session for
regular use, verify password unlocking and suspend/resume on your machine.

To customize the shell, start with its settings panel or the files listed in
[the customization section](README.md#customize).

## 10. Return to your previous desktop or disable Caelestia

To switch back, save your work, log out, select your previous Ubuntu/GNOME/Hyprland
session, and sign in normally.

To disable only the Caelestia login option, run from your existing desktop:

```bash
cd "$HOME/Downloads/Caelestia-ubuntu"
sudo bash platform/ubuntu/unregister-session.sh
```

This keeps your other sessions, private Caelestia files, and installed Ubuntu
packages. It does not automatically remove dependencies.

## Common problems

| Problem | What to check |
| --- | --- |
| `git: command not found` | Complete step 2. |
| Clone says the destination already exists | Use `cd "$HOME/Downloads/Caelestia-ubuntu"` if it is your earlier clone. Do not delete an existing folder blindly. |
| `No such file or directory` for an installer script | Return to the project folder from step 3. |
| Dependency installer rejects the Ubuntu release | It supports Ubuntu 26.04 only; older releases need a separate port. |
| APT cannot locate packages | Check your Ubuntu release, successful `apt update`, and whether the official Universe repository is enabled. |
| Qt/Python version or missing-tool error | Complete step 4 and resolve the package conflict reported by APT. Do not use system-wide `sudo pip`. |
| Build appears busy for a long time | Source compilation takes time. If it fails with a compiler process killed for lack of memory, retry with one build job. |
| Startup check fails | Inspect the logs below and resolve the error before registering the session. |
| Login returns to the greeter | Select your previous desktop and inspect `shell.log`. |

Startup-test logs:

```bash
tail -n 80 "$HOME/.local/share/caelestia-ubuntu/cache/startup-check.log"
tail -n 80 "$HOME/.local/share/caelestia-ubuntu/cache/startup-compositor.log"
```

Actual-session shell log:

```bash
tail -n 80 "$HOME/.local/share/caelestia-ubuntu/cache/shell.log"
```

When reporting an issue, include your Ubuntu version, session type, and relevant
error lines. Review logs before posting them publicly.

For subsequent updates, follow [the update instructions](README.md#update).
Existing installations can apply the [performance settings](README.md#performance)
with `bash platform/ubuntu/optimize.sh` from the project folder.
