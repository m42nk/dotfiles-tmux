#!/usr/bin/env python3

import argparse
import subprocess
import os
import tempfile

"""
- User able to see the list of directories from config
- User able to select a directory and create new session
- User able to select a directory and attach to existing session if exists
"""

SEARCHMODES = ["all", "session", "dir"]
SEARCHMODE_DEFAULT = "all"

KEY_SEARCHMODE_NEXT = "ctrl-n"
KEY_SEARCHMODE_PREV = "ctrl-p"

SCRIPT_PATH = os.path.realpath(__file__)

TMP_DIR = tempfile.mkdtemp()
TMP_MODE = os.path.join(TMP_DIR, "mode")

print(f"TMP_DIR: {TMP_DIR}")


def main():
    args = args_parse()

    with open(TMP_MODE, "w") as f:
        current_mode = args.searchmode
        f.write(current_mode)
        f.write(get_prev_mode(current_mode))
        f.write(get_next_mode(current_mode))

    fuzzy_find(args.searchmode)


def args_parse():
    parser = argparse.ArgumentParser()

    parser.add_argument(
        "--static",
        action="store_true",
        default=False,
        help="get result only and skip fuzzy search",
    )

    parser.add_argument(
        "--searchmode",
        type=str,
        help="search mode",
        default=SEARCHMODE_DEFAULT,
        choices=SEARCHMODES,
    )

    return parser.parse_args()


def fuzzy_find(current_mode):
    # + f"{KEY_SEARCHMODE_NEXT}:become({SCRIPT_PATH} --searchmode {next_mode(current_mode)})",
    # + f"{KEY_SEARCHMODE_PREV}:become({SCRIPT_PATH} --searchmode {get_prev_mode(current_mode)})",
    prev_mode, next_mode = get_prev_mode(current_mode), get_next_mode(current_mode)
    subprocess.run(
        [
            "fzf",
            "--ansi",
            "--header=" + get_header(current_mode),
            "--bind=" + f"{KEY_SEARCHMODE_NEXT}:change-header({get_header(next_mode)})",
            "--bind=" + f"{KEY_SEARCHMODE_PREV}:change-header({get_header(prev_mode)})",
        ]
    )


def get_header(current_mode):
    header = f"Press {KEY_SEARCHMODE_NEXT}/{KEY_SEARCHMODE_PREV} to switch mode: "
    return f"{header}\n{get_header_modes(current_mode)}"


def get_next_mode(current_mode):
    return SEARCHMODES[(SEARCHMODES.index(current_mode) + 1) % len(SEARCHMODES)]


def get_prev_mode(current_mode):
    return SEARCHMODES[(SEARCHMODES.index(current_mode) - 1) % len(SEARCHMODES)]


def get_header_modes(current_mode):
    c_bold = subprocess.getoutput("tput bold")
    c_reset = subprocess.getoutput("tput sgr0")

    header_modes = []
    for mode in SEARCHMODES:
        if mode == current_mode:
            header_modes.append(f"[{c_bold}{mode}{c_reset}]")
        else:
            header_modes.append(mode)

    return " ".join(header_modes)


if __name__ == "__main__":
    main()
