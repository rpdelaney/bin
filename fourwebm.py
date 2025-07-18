#!/usr/bin/env python3
"""Encode an input media file as a webm clip.

Calculates bitrate to achieve a target file size.
"""

import argparse
import datetime
import multiprocessing
import os
import shutil
import subprocess
import tempfile

from collections.abc import Iterator


# constants
AUDIO_BITRATE = 96


def parse_args() -> argparse.Namespace:
    """Define an argument parser and return the parsed arguments."""
    default_threads = multiprocessing.cpu_count() - 1
    parser = argparse.ArgumentParser(
        prog="4webm",
        description="creates clips from video files using ffmpeg",
    )
    parser.add_argument(
        "--input-file", "-i", help="input video file", required=True
    )
    parser.add_argument(
        "--engine",
        "-e",
        help="path to ffmpeg (default: %(default)s)",
        default="ffmpeg",
    )
    parser.add_argument(
        "--start",
        "-ss",
        help="beginning timestamp (default: %(default)s)",
        type=str,
        default="00:00:00.00",
    )
    parser.add_argument(
        "--stop", "-st", "-to", help="ending timestamp", default=None
    )
    parser.add_argument(
        "--no-audio",
        "-na",
        help="exclude audio",
        action="store_true",
        default=False,
    )
    parser.add_argument(
        "--size",
        help="target size in megabytes (default: %(default)s)",
        type=float,
        default="4.00",
    )
    parser.add_argument(
        "--postview",
        "-p",
        help="attempt to play the video after it's created",
        action="store_true",
    )
    parser.add_argument(
        "--threads",
        help="how many threads to use when encoding (default: %(default)s)",
        default=default_threads,
    )
    parser.add_argument(  # TODO: this still creates an empty temporary file
        "--dry-run",
        "-n",
        help="print the command that would be executed",
        action="store_true",
        default=False,
    )
    parser.add_argument(
        "--loop",
        "-l",
        help="make a reversed loop or 'infinite loop'",
        action="store_true",
        default=False,
    )

    return parser.parse_args()


def get_video_length(target: str) -> str:
    """Use ffprobe to determine the duration of a target video file."""
    result = subprocess.run(
        ["ffprobe", "-hide_banner", "-print_format", "json", target],
        capture_output=True,
        check=True,
        timeout=10,
        encoding="utf-8",
    )
    data = ", ".join([x for x in result.stderr.split("\n") if "Duration" in x])
    data = data.replace("Duration:", "").strip()
    items = data.split(", ")
    duration = items[0].split(":")

    return ":".join(duration)


def get_new_file_name(filename: str) -> Iterator[str]:
    """Yield an appropriate output filename.

    Format: [ORIGINAL_FILE_BASENAME]-[INDEX].webm

    where [INDEX] is a zero-padded integer starting at 01 and increasing

    special characters (non-alpha, non-digit) will be omitted and spaces will
    be converted to '.'
    """
    try:
        i: int
        _ = i
    except NameError:
        i = 1

    basename = os.path.basename(filename)
    splitname = os.path.splitext(basename)[0]
    fullname = "{}-{:02d}{}".format(splitname, i, ".webm")

    # we could use string.ascii_characters and string.digits, but that would
    # miss anything outside of ASCII space
    keepcharacters = (" ", ".", "_", "-")
    finalname = "".join(
        [
            (
                c
                if c.isalpha()
                or c.isdigit()
                or c.isalnum()
                or c in keepcharacters
                else "_"
            )
            for c in fullname
        ]
    ).rstrip()
    finalname = finalname.replace(" ", ".")

    i = i + 1
    yield finalname


def encode(command: list[str]) -> None:
    """Execute the provided string as a subprocess call.

    Presumes this is a call to ffmpeg.

    Args:
        command (list):    the command to execute

    Returns:
        None

    Raises:
        subprocess.CalledProcessError: If the subprocess call exited non-zero.
    """
    process = subprocess.Popen(
        command, stdout=subprocess.PIPE, universal_newlines=True
    )
    return_code = process.wait()
    if return_code:
        raise subprocess.CalledProcessError(return_code, command)


def main() -> None:
    """Main cli entry point."""
    args = parse_args()

    audiocodec = "libopus"

    temp_file = tempfile.NamedTemporaryFile(suffix=".webm", delete=False)
    log_file = tempfile.NamedTemporaryFile(suffix="-0.log", delete=False)

    start = datetime.datetime.strptime(args.start, "%H:%M:%S.%f").time()  # noqa: DTZ007
    if args.stop:
        stop = datetime.datetime.strptime(args.stop, "%H:%M:%S.%f").time()  # noqa: DTZ007
    else:
        stop = datetime.datetime.strptime(  # noqa: DTZ007
            get_video_length(args.input_file), "%H:%M:%S.%f"
        ).time()
    print(f"stop: {stop}")

    delta = datetime.datetime.combine(
        datetime.date.min, stop
    ) - datetime.datetime.combine(datetime.date.min, start)
    length = delta.total_seconds()
    if length < 0:
        errmsg = f"Video length was less than 0 seconds {length}"
        raise RuntimeError(errmsg)
    if length >= 300:  # maximum video length is 5 minutes  # noqa: PLR2004
        errmsg = f"Video length was greater than 300 seconds: {length}"
        raise RuntimeError(errmsg)

    target_size_kbit = args.size * 8 * 1024
    if not args.no_audio:
        sound_size_kbit = round(length * AUDIO_BITRATE)
        target_size_kbit = target_size_kbit - sound_size_kbit
    bitrate_kbit = round(target_size_kbit / length)

    command1 = [
        "ffmpeg",
        "-y",
        "-i",
        args.input_file,
        "-vf",
        "scale=640:360:force_original_aspect_ratio=decrease",
        "-pass",
        "1",
        # where to put the log file for first pass
        "-passlogfile",
        log_file.name,
        # set the video bitrate
        "-b:v",
        str(bitrate_kbit) + "K",
        # start and stop timestamps
        "-ss",
        args.start,
        "-to",
        stop.strftime("%H:%M:%S"),
        # use multithreading
        "-threads",
        str(args.threads),
        # Maximum keyframe interval (frames)
        "-g",
        "9999",
        # force output format to webm
        "-f",
        "webm",
        # disable audio (since we're doing the first pass)
        "-an",
        #  set video codec
        "-c:v",
        "libvpx-vp9",
        "-tile-columns",
        "0",
        "-frame-parallel",
        "0",
        "-speed",
        "4",
        "/dev/null",
    ]
    command2 = [
        "ffmpeg",
        "-y",
        "-i",
        args.input_file,
        "-vf",
        "scale=640:360:force_original_aspect_ratio=decrease",
        "-pass",
        "2",
        # where to put the log file for first pass
        "-passlogfile",
        log_file.name,
        # set the video bitrate
        "-b:v",
        str(bitrate_kbit) + "K",
        # start and stop timestamps
        "-ss",
        args.start,
        "-to",
        stop.strftime("%H:%M:%S"),
        # use multithreading
        "-threads",
        str(args.threads),
        # force output format to webm
        "-f",
        "webm",
        "-metadata",
        f"title={os.path.basename(args.input_file)}",
        # set video codec
        "-c:v",
        "libvpx-vp9",
        "-tile-columns",
        "0",
        "-frame-parallel",
        "0",
        "-auto-alt-ref",
        "1",
        # number of frames to look ahead for when encoding
        # 0 means no limit
        "-lag-in-frames",
        "0",
        "-speed",
        "1",
    ]

    if args.no_audio:
        command2.append("-an")
    else:
        command2 += [
            "-c:a",
            audiocodec,  # use codec for audio
            "-b:a",
            str(AUDIO_BITRATE) + "k",  # set audio bitrate
        ]

    command2.append(temp_file.name)

    if not args.dry_run:
        print(" ".join(command1))
        encode(command1)
        print(" ".join(command2))
        encode(command2)

    # Figure out a name for the ile
    file_dest = get_new_file_name(args.input_file)

    while True:
        try:
            new_file = shutil.move(
                temp_file.name, os.path.join(os.getcwd(), next(file_dest))
            )
        except OSError:
            continue
        else:
            break

    # Try to view the file
    if args.postview:
        try:
            subprocess.call(["mpv", "-loop-playlist", new_file])
        except OSError:
            print("Failed to play the video. Is mpv in your $PATH?")


if __name__ == "__main__":
    main()
