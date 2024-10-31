#!/usr/bin/env python3
#
"""Facilitates manipulating the shell PATH in a very over-engineered kind of way."""
import argparse
import os
import sys

from contextlib import suppress
from pathlib import Path


class ShellPath:
    def __init__(self, path_env):
        # deduplicate the $PATH
        self.paths = []
        for item in [Path(item) for item in path_env.split(":")]:
            if item not in self.paths:
                self.paths.append(item)

    def append(self, new_path):
        if new_path not in self.paths:
            self.paths.append(Path(new_path))

    def prepend(self, new_path):
        self.delete(new_path)
        self.paths.insert(0, new_path)

    def delete(self, target_path):
        with suppress(ValueError):
            self.paths.remove(target_path)


def parse_args() -> argparse.Namespace:
    """Define an argument parser and return the parsed arguments."""
    parser = argparse.ArgumentParser(
        prog="path",
        description="does some manipulations to PATH in a "
        "very over-engineered kind of way",
    )
    parser.add_argument("command", choices=("append", "prepend", "delete"))
    parser.add_argument("path")

    return parser.parse_args()


def main() -> None:
    args = parse_args()
    paths = ShellPath(os.environ.get("PATH"))

    match args.command:
        case "append":
            paths.append(Path(args.path).absolute())
        case "prepend":
            paths.prepend(Path(args.path).absolute())
        case "delete":
            paths.delete(Path(args.path).absolute())

    print(":".join(str(path) for path in paths.paths))


if __name__ == "__main__":
    main()

# EOF
