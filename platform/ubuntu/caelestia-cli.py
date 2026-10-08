#!/usr/bin/env python3
"""Ubuntu session CLI adapter for Catppuccin's separate light/dark flavours."""
from pathlib import Path

from caelestia.parser import parse_args
from caelestia.subcommands.scheme import Set
from caelestia.utils.io import log
from caelestia.utils.paths import c_state_dir, atomic_write
from caelestia.utils.scheme import get_scheme
from caelestia.utils.version import print_version

DARK_FLAVOURS = {"mocha", "frappe", "macchiato"}


def main():
    parser, args = parse_args()
    remembered = Path(c_state_dir) / "catppuccin-dark-flavour.txt"
    is_set = getattr(args, "cls", None) is Set
    if is_set and args.mode in {"light", "dark"}:
        current = get_scheme()
        if (args.name or current.name) == "catppuccin":
            if current.name == "catppuccin" and current.flavour in DARK_FLAVOURS:
                atomic_write(remembered, current.flavour)
            if args.mode == "light":
                args.flavour = "latte"
            elif args.flavour not in DARK_FLAVOURS:
                try:
                    previous = remembered.read_text().strip()
                except FileNotFoundError:
                    previous = "mocha"
                args.flavour = previous if previous in DARK_FLAVOURS else "mocha"
    if args.version:
        print_version()
    elif "cls" in args:
        args.cls(args).run()
        if is_set:
            current = get_scheme()
            if current.name == "catppuccin" and current.flavour in DARK_FLAVOURS:
                atomic_write(remembered, current.flavour)
    else:
        parser.print_help()


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        log("Exiting...")
