#!/usr/bin/env python3
#
import re
import time
import sys
import subprocess
from pathlib import Path


DEBUG = True


def debug(line: str) -> None:
    if DEBUG:
        print(line, file=sys.stderr)


class FakeCompletedProcess:
    def __init__(
        self,
        returncode: int = 0,
        stdout: str = "",
        stderr: str = "",
    ):
        self.returncode = returncode
        self.stdout = stdout
        self.stderr = stderr


def uncolor(string: str) -> str:
    """Remove ANSI escape sequences from a string."""
    return re.sub(r"\x1B(?:[@-Z\\-_]|\[[0-?]*[ -/]*[@-~])", "", string)


def cmd(command: str) -> int:
    """Thinly wrap subprocess.run, accepting strings and capturing output."""
    # TODO: catch KeyboardInterrupt and handle it somehow?
    # TODO: use subprocess.Popen so we can display the output of slow-
    #       running commands in real time
    debug(f"EXEC --> {command}")
    cmd_proc = subprocess.run(
        command.split(),
        capture_output=True,
    )

    if cmd_proc.returncode != 0:
        print("command failed. stderr:", file=sys.stderr)
        print(cmd_proc.stderr.decode(), file=sys.stderr)

    return cmd_proc


def get_plan_filename() -> str:
    """Calculate the filename for the plan we output.

    If on git:
        ~{branch_name}__{epoch}__.plan
    Else:
        ~{epoch}__.plan

    Replace some characters in {branch_name}, that terraform can
    get confused by.
    """
    epoch = int(time.time())
    plan_filename = f"{epoch}__.plan"

    p = subprocess.run(
        "git rev-parse --abbrev-ref HEAD".split(" "), capture_output=True
    )
    if p.returncode == 0:
        branch_name = p.stdout.decode().strip()
        branch_name = branch_name.replace("/", "_").replace(" ", "_")
        plan_filename = f"{branch_name}__{plan_filename}"

    return f"~{plan_filename}"


def main() -> None:
    if len(sys.argv) > 1:
        subcmd = sys.argv[1]
        subargs = " ".join(sys.argv[2:])
    else:
        subcmd = "version"
        subargs = ""

    match subcmd:
        case "version":
            r = cmd(f"terraform version -json {subargs}")
            if r.returncode == 0:
                stdout = r.stdout.decode()
                print(stdout)

        case "init":
            r = cmd(f"terraform init -input=false {subargs}")

        case "import":
            r = cmd(f"terraform import -input=false {subargs}")

        case "plan":
            r = cmd(
                f"terraform plan -input=false -compact-warnings "
                f"-out={get_plan_filename()} {subargs}"
            )

        case "show":
            # TODO: add tf-summarize:
            # /opt/homebrew/bin/tf-summarize -tree "$file" | tee "~${file}.plan.summary.txt"
            pwd = Path(".")
            planfiles = [str(_p) for _p in pwd.glob("*.plan")]
            for planfile in planfiles:
                print(f"### {planfile} ##########")
                r = cmd(f"terraform show {planfile} {subargs}")
                if r.returncode == 0:
                    stdout = r.stdout.decode()
                    print(stdout)

                    # remove ANSI colors and write to file.
                    # we could use `terraform show -no-color`,
                    # but this is faster
                    stdout_uncolored = uncolor(stdout)
                    with open(f"{planfile}.hcl", "w+") as f:
                        f.write(stdout_uncolored)
                else:
                    print(r.stderr.decode())
                    break
            else:
                # exit with error later
                r = FakeCompletedProcess(1)

        case _:
            r = cmd(f"terraform {subcmd} {subargs}")

    # I use a script called `notice` to send notifications that always reach me
    n_proc = cmd(f"notice terraform {subcmd} done")
    if n_proc.returncode != 0:
        print("notice command failed. stderr:", file=sys.stderr)
        print(n_proc.stderr.decode() or "", file=sys.stderr)
        return n_proc.returncode

    try:
        return r.returncode
    except UnboundLocalError:
        return 0


if __name__ == "__main__":
    sys.exit(main())

# EOF
