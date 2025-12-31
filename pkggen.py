#!/usr/bin/env python3
#
# This Python script reads lines from standard input or files specified
# as command-line arguments, processes them to extract texture asset
# information, and outputs a JSON structure for a ddinfo-tools package.
#
# example usage:
#   $ ls -1 ./Textures/* | xargs readlink -f | pkggen.py > pkg.json
import fileinput
import json

from pathlib import Path


"""
directory = Path('your_directory_path')
files = [file for file in directory.rglob('*') if file.is_file()]
"""

textures = []

for filepath in [Path(line.strip()) for line in fileinput.input()]:
    if not filepath:
        continue  # Skip empty lines
    if ".bak" in str(filepath):
        continue  # Skip backup files

    # Optionally replace the base path
    absolute_path = str(filepath).replace(
        "/home/ryan/.local/share/Steam/",
        "/home/ryan/.steam/steam/",
    )

    textures.append(
        {
            "AssetName": Path(filepath).stem,
            "AbsolutePath": absolute_path,
        }
    )

output = {
    "Audio": [],
    "Meshes": [],
    "ObjectBindings": [],
    "Shaders": [],
    "Textures": textures,
}

print(json.dumps(output, indent=2, sort_keys=True))
