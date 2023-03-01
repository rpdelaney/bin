#!/usr/bin/env python3
#
from rich.console import Console


styles = [
    "bold",
    "italic",
    "reverse",
    "strike",
    "underline",
    #Rich also supports the following styles, which are not well supported and may not display in your terminal:
    "underline2",
    "frame",
    "encircle",
    "overline",
]

def main() -> None:
    console = Console()

    for style in styles:
        console.print(f"""the quick brown fox jumps over the lazy dog""", style=style, end="")
        print(f"     {style}")


if __name__ == "__main__":
    main()

# EOF
