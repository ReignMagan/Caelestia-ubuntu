#!/usr/bin/env python3
"""Recover shell crashes within this compositor session, never after logout."""
from collections import deque
import os
import select
import signal
import socket
import subprocess
import time


def supervise():
    connection = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    connection.connect(f"{os.environ['XDG_RUNTIME_DIR']}/hypr/"
                       f"{os.environ['HYPRLAND_INSTANCE_SIGNATURE']}/.socket2.sock")
    crashes = deque()
    child = None

    def stop(_signal, _frame):
        raise SystemExit(0)

    signal.signal(signal.SIGTERM, stop)
    signal.signal(signal.SIGINT, stop)
    try:
        while True:
            child = subprocess.Popen(["qs", "-c", "caelestia", "-n"])
            while child.poll() is None:
                if select.select([connection], [], [], 1)[0] and not connection.recv(65536):
                    return
            status = child.returncode
            if status == 0:
                return  # Respect an intentional `qs kill` or duplicate instance.
            now = time.monotonic()
            while crashes and crashes[0] < now - 60:
                crashes.popleft()
            crashes.append(now)
            print(f"Caelestia exited unexpectedly ({status}); crash count: {len(crashes)}", flush=True)
            if len(crashes) >= 3:
                print("Stopping automatic recovery after repeated crashes.", flush=True)
                return
            # Brief backoff; continue watching for compositor shutdown.
            end = now + 1
            while time.monotonic() < end:
                if select.select([connection], [], [], max(0, end - time.monotonic()))[0]:
                    if not connection.recv(65536):
                        return
    finally:
        connection.close()
        if child is not None and child.poll() is None:
            child.terminate()
            try:
                child.wait(timeout=3)
            except subprocess.TimeoutExpired:
                child.kill()
                child.wait()


if __name__ == "__main__":
    supervise()
