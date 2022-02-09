#!/usr/bin/env python3
#
"""
halp.py

Usage: halp cOmMaNdIdOnTkNoW

some utils have their own idea of whether it should be '--help' or '-h' or '-?'
or some random combination and I'm tired of guessing when I'm in the midst of
trying to figure something else out

TODO: also, I like to page the output if it's long, but some commands
print help text to stdout and others to stderr. who wants to type '&> | pager'
all the damn time? not me.
"""
import sys
import os
import subprocess
import shutil
from typing import List

COMMAND = sys.argv[1]

TRIES = (
    f"{COMMAND} -h",
    f"{COMMAND} -?",
    f"{COMMAND} --help",
    f"{COMMAND} -help",
    f"tldr {COMMAND}",
    f"man {COMMAND}",
    f"info {COMMAND}",
)

PAGER = os.environ.get("PAGER") or ""


def is_oversized(text: List[str]) -> bool:
    """
    return whether the text is too big for the terminal
    might use this to fix the TODO
    """
    width = max(len(line) for line in text)
    size = shutil.get_terminal_size()
    return width > size.columns or len(text) > size.lines


def main() -> None:
    # hold up: does this thing even exist on the system?
    if not shutil.which(COMMAND):
        print(f"Command not found: {COMMAND}")
        return 1

    for command in TRIES:
        p = subprocess.run(command.split(" "), capture_output=True)
        try:
            p.check_returncode()
        except subprocess.CalledProcessError:
            continue
        else:
            print(f"+ {command}")
            output = p.stdout.decode() + p.stderr.decode()
            # TODO: page the output if it's too big for the terminal
            print(output)
            return


if __name__ == "__main__":
    sys.exit(main())

# EOF
