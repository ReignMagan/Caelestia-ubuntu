#!/usr/bin/python3
"""Ubuntu system proxy settings. No daemon, tunnel, or shell interpolation."""
import ipaddress
import json
import re
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
            "automatic": mode == "auto"}


def apply(request, root):
    action = request.get("action", "status")
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
    except (ValueError, TypeError) as error:
        result = {"ok": False, "error": str(error)}
    print(json.dumps(result), flush=True)


if __name__ == "__main__":
    main()
