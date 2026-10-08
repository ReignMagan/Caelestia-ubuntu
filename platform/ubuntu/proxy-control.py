#!/usr/bin/python3
"""Ubuntu system proxy settings. No daemon, tunnel, or shell interpolation."""
import ipaddress
import json
import re
import os
from pathlib import Path
import subprocess
import sys
from gi.repository import Gio


def validate(host, port, kind):
    host = str(host).strip()
    if kind not in {"http", "socks"}:
        raise ValueError("Choose HTTP/HTTPS or SOCKS.")
    try:
        port = int(str(port))
    except ValueError:
        raise ValueError("Port must be a number from 1 to 65535.") from None
    if not 1 <= port <= 65535:
        raise ValueError("Port must be a number from 1 to 65535.")
    try:
        ipaddress.ip_address(host)
    except ValueError:
        if len(host) > 253 or not re.fullmatch(r"[A-Za-z0-9](?:[A-Za-z0-9.-]*[A-Za-z0-9])?", host):
            raise ValueError("Enter a hostname or IP address, without a URL or port.")
        if any(not part or len(part) > 63 or part.startswith("-") or part.endswith("-") for part in host.split(".")):
            raise ValueError("Enter a valid hostname or IP address.")
    return host, port


def settings():
    return Gio.Settings.new("org.gnome.system.proxy")


def snapshot(root):
    http, socks = root.get_child("http"), root.get_child("socks")
    kind = "http" if http.get_string("host") or not socks.get_string("host") else "socks"
    child = http if kind == "http" else socks
    mode = root.get_string("mode")
    return {"mode": mode, "enabled": mode != "none", "kind": kind,
            "host": child.get_string("host"), "port": child.get_int("port") or 8080,
            "automatic": mode == "auto", "browserRestartRequired": brave_needs_restart()}


def brave_needs_restart():
    for process in Path("/proc").glob("[0-9]*"):
        try:
            if process.stat().st_uid != os.getuid():
                continue
            command = (process / "cmdline").read_bytes().split(b"\0")
            if not command or not command[0].endswith(b"/brave"):
                continue
            if any(arg.startswith(b"--type=") or arg.startswith(b"--headless") for arg in command):
                continue
            environment = dict(part.split(b"=", 1) for part in (process / "environ").read_bytes().split(b"\0") if b"=" in part)
            if b"GNOME" not in environment.get(b"XDG_CURRENT_DESKTOP", b"").split(b":"):
                return True
        except OSError:
            pass
    return False


def test_connection(root):
    state = snapshot(root)
    if not state["host"]:
        raise ValueError("Enter a hostname and port first.")
    host, port = validate(state["host"], state["port"], state["kind"])
    host = f"[{host}]" if ":" in host else host
    protocol = "socks5h" if state["kind"] == "socks" else "http"
    result = subprocess.run([
        "/usr/bin/curl", "--noproxy", "", "--proxy", f"{protocol}://{host}:{port}",
        "--connect-timeout", "4", "--max-time", "8", "--silent", "--show-error",
        "--output", "/dev/null", "--write-out", "%{http_code}", "https://example.com",
    ], capture_output=True, text=True, timeout=10)
    success = result.returncode == 0 and result.stdout.strip() == "200"
    messages = {5: "Proxy hostname could not be resolved.", 7: "Cannot connect to the proxy hostname and port.",
                28: "The proxy connection timed out.", 97: "SOCKS connection failed; check the proxy type."}
    message = "Proxy connection verified." if success else messages.get(result.returncode, "Proxy test failed; check the address and proxy type.")
    if result.stdout.strip() == "407" or "407" in result.stderr:
        message = "This proxy requires authentication."
    return {"ok": True, **state, "testMessage": message, "testOk": success}


def apply(request, root):
    action = request.get("action", "status")
    if action == "test":
        return test_connection(root)
    if action == "save":
        host, port = validate(request.get("host", ""), request.get("port", ""), request.get("kind"))
        kind = request["kind"]
        # Store all changes before notifying clients through the dconf service.
        root.delay()
        children = []
        for name in ("http", "https", "ftp", "socks"):
            child = root.get_child(name)
            child.delay()
            selected = name in ("http", "https") if kind == "http" else name == "socks"
            child.set_string("host", host if selected else "")
            child.set_int("port", port if selected else 0)
            if name == "http":
                child.set_boolean("use-authentication", False)
            children.append(child)
        root.set_boolean("use-same-proxy", False)
        root.set_string("mode", "manual" if request.get("enabled", True) else "none")
        for child in children:
            child.apply()
        root.apply()
        Gio.Settings.sync()
    elif action == "toggle":
        if request.get("enabled"):
            state = snapshot(root)
            if state["host"]:
                validate(state["host"], state["port"], state["kind"])
                root.set_string("mode", "manual")
            elif root.get_string("autoconfig-url"):
                root.set_string("mode", "auto")
            else:
                raise ValueError("Enter a hostname and port first.")
        else:
            root.set_string("mode", "none")
        Gio.Settings.sync()
    elif action != "status":
        raise ValueError("Unknown proxy action.")
    return {"ok": True, **snapshot(root)}


def main():
    try:
        request = json.loads(sys.stdin.readline() or '{"action":"status"}')
        result = apply(request, settings())
    except subprocess.TimeoutExpired:
        result = {"ok": False, "error": "The proxy connection timed out."}
    except (ValueError, TypeError) as error:
        result = {"ok": False, "error": str(error)}
    print(json.dumps(result), flush=True)


if __name__ == "__main__":
    main()
