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

PORT = 6266

MODES = ["all", "session", "dir"]
MODE_DEFAULT = "all"

KEY_MODE_NEXT = "ctrl-n"
KEY_MODE_PREV = "ctrl-p"

SCRIPT_PATH = os.path.realpath(__file__)

TMP_DIR = tempfile.gettempdir()
TMP_MODE = os.path.join(TMP_DIR, "tmux-launcher-mode")


# TODO: this is working, cleanup and refactor
def main():
    args = args_parse()

    # Create the file with default mode if it doesn't exist
    if not os.path.exists(TMP_MODE):
        with open(TMP_MODE, "w") as f:
            f.write(MODE_DEFAULT)

    mode = build_mode(args)
    content = get_content(mode)
    header = build_header(mode)

    if args.static:
        if args.static == "header":
            print(header)
        elif args.static == "content":
            print(content)
        return

    fuzzy_find(content, header)


def args_parse():
    parser = argparse.ArgumentParser()

    parser.add_argument(
        "--static",
        type=str,
        nargs="?",
        const=True,
        default=None,
        choices=["header", "content"],
        help="get static text only and skip fuzzy search",
    )

    parser.add_argument(
        "--mode",
        type=str,
        help="search mode",
        choices=MODES + ["next", "prev"],
    )

    return parser.parse_args()


def get_content(mode):
    if mode == "all":
        return "hello from all"
    elif mode == "session":
        return "hello from session"
    elif mode == "dir":
        return "hello from dir"
    else:
        raise ValueError(f"Unknown mode: {mode}")


def fuzzy_find(content, header):
    # TODO: handle output

    subprocess.run(
        [
            "fzf",
            f"--listen={PORT}",
            "--ansi",
            "--header=" + header,
            f"--bind={KEY_MODE_NEXT}:execute-silent({SCRIPT_PATH} --static --mode next)"
            f"+reload({SCRIPT_PATH} --static content)"
            f"+transform-header({SCRIPT_PATH} --static header)",
            f"--bind={KEY_MODE_PREV}:execute-silent({SCRIPT_PATH} --static --mode prev)"
            f"+reload({SCRIPT_PATH} --static content)"
            f"+transform-header({SCRIPT_PATH} --static header)",
        ],
        input=content.encode(),
        text=False,
    )


def build_header(current_mode):
    header = f"Press {KEY_MODE_NEXT}/{KEY_MODE_PREV} to switch mode: "
    return f"{header}\n{build_header_modes(current_mode)}"


def build_header_modes(current_mode):
    c_bold = subprocess.getoutput("tput bold")
    c_reset = subprocess.getoutput("tput sgr0")

    header_modes = []
    for mode in MODES:
        if mode == current_mode:
            header_modes.append(f"[{c_bold}{mode}{c_reset}]")
        else:
            header_modes.append(mode)

    return " ".join(header_modes)


def get_next_mode(current_mode):
    return MODES[(MODES.index(current_mode) + 1) % len(MODES)]


def get_prev_mode(current_mode):
    return MODES[(MODES.index(current_mode) - 1) % len(MODES)]


def build_mode(args):
    if args.static:
        current_mode = get_stored_mode()
    else:
        current_mode = args.mode or MODE_DEFAULT
        set_stored_mode(current_mode)

    mode = current_mode
    if args.mode in ["next", "prev"]:
        mode = get_next_mode(mode) if args.mode == "next" else get_prev_mode(mode)
        set_stored_mode(mode)

    return mode


def get_stored_mode():
    if os.path.exists(TMP_MODE):
        with open(TMP_MODE, "r") as f:
            return f.read().strip()

    return MODE_DEFAULT


def set_stored_mode(mode):
    with open(TMP_MODE, "w") as f:
        f.write(mode)


if __name__ == "__main__":
    main()
