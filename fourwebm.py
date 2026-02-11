#!/usr/bin/env python3
"""Encode an input media file as a mp4 clip.

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

    Format: [ORIGINAL_FILE_BASENAME]-[INDEX].mp4

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
    fullname = "{}-{:02d}{}".format(splitname, i, ".mp4")

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
    console = Console()
    console.rule()
    console.out(command, highlight=True)
    console.rule()

    process = subprocess.Popen(
        command, stdout=subprocess.PIPE, universal_newlines=True
    )
    return_code = process.wait()
    if return_code:
        raise subprocess.CalledProcessError(return_code, command)


def main() -> None:
    """Main cli entry point."""
    args = parse_args()

    audiocodec = "aac"

    temp_file = tempfile.NamedTemporaryFile(suffix=".mp4", delete=False)
    log_file = tempfile.NamedTemporaryFile(suffix="-0.log", delete=False)

    start = datetime.datetime.strptime(args.start, "%H:%M:%S.%f").time()  # noqa: DTZ007
    if args.stop:
        stop = datetime.datetime.strptime(args.stop, "%H:%M:%S.%f").time()  # noqa: DTZ007
    else:
        stop = datetime.datetime.strptime(  # noqa: DTZ007
            get_video_length(args.input_file), "%H:%M:%S.%f"
        ).time()

    delta = datetime.datetime.combine(
        datetime.date.min, stop
    ) - datetime.datetime.combine(datetime.date.min, start)
    length = delta.total_seconds()
    if length <= 0:
        errmsg = f"Video length was less than or equal to 0 seconds: {length}"
        raise RuntimeError(errmsg)

    target_size_kbit = args.size * 8 * 1024
    if not args.no_audio:
        sound_size_kbit = round(length * AUDIO_BITRATE)
        target_size_kbit = target_size_kbit - sound_size_kbit
    bitrate_video_kbit = round(target_size_kbit / length)

    command1 = [
        "ffmpeg",
        "-y",
        "-i",
        args.input_file,
        # downscale to 640:640, or closest possible,
        # without mangling aspect ratio
        "-vf",
        # set filters
        r"format=yuv420p,fps=30000/1001,scale=trunc(iw*min(640/iw\,640/ih)/2)*2:trunc(ih*min(640/iw\,640/ih)/2)*2",
        # set the video bitrate
        "-b:v",
        str(bitrate_video_kbit) + "k",
        # start and stop timestamps
        "-ss",
        args.start,
        "-to",
        stop.strftime("%H:%M:%S.%f"),
        # use multithreading
        "-threads",
        str(args.threads),
        # output no files (since we're doing the first pass)
        "-f",
        "null",
        # disable audio (since we're doing the first pass)
        "-an",
        # faster streaming/startup
        "-movflags",
        "+faststart",
        # set video codec
        "-c:v",
        "libx264",
        "-preset",
        "slow",
        "-pass",
        "1",
        # force constant timing
        "-fps_mode",
        "cfr",
        # write data to null
        # (since we don't actually produce a video on this step)
        "-",
    ]
    command2 = [
        "ffmpeg",
        "-y",
        "-i",
        args.input_file,
        # set filters
        "-vf",
        r"format=yuv420p,fps=30000/1001,scale=trunc(iw*min(640/iw\,640/ih)/2)*2:trunc(ih*min(640/iw\,640/ih)/2)*2",
        # set the video bitrate
        "-b:v",
        str(bitrate_video_kbit) + "k",
        # start and stop timestamps
        "-ss",
        args.start,
        "-to",
        stop.strftime("%H:%M:%S.%f"),
        # use multithreading
        "-threads",
        str(args.threads),
        # force output format to mp4
        "-f",
        "mp4",
        # write the original filename into the metadata
        "-metadata",
        f"title={os.path.basename(args.input_file)}",
        # downmix audio to stereo
        "-ac",
        "2",
        # set video codec
        "-c:v",
        "libx264",
        "-preset",
        "slow",
        "-pass",
        "2",
        # force constant timing
        "-fps_mode",
        "cfr",
        # explicitly set the sample entry for maximum compatibility
        "-tag:v",
        "avc1",
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
        encode(command1)
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
