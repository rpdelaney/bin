#!/usr/bin/env python3
#
import argparse
import os
import sys
from pathlib import Path
from contextlib import suppress


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
        else:
            print(
                f"Warning: new path was already present: {new_path}",
                file=sys.stderr,
            )

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
    parser.add_argument(
        "command",
        choices=("append", "prepend", "delete")
    )
    parser.add_argument("path")

    return parser.parse_args()


def main() -> None:
    args = parse_args()
    paths = ShellPath(os.environ.get("PATH"))

    if args.command == "append":
        paths.append(Path(args.path).absolute())
    elif args.command == "prepend":
        paths.prepend(Path(args.path).absolute())
    elif args.command == "delete":
        paths.delete(Path(args.path).absolute())

    print(":".join(str(path) for path in paths.paths))


if __name__ == "__main__":
    main()

# EOF