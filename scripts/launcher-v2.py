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

    if not os.path.exists(TMP_MODE):
        f = open(TMP_MODE, "w")
        f.write(MODE_DEFAULT)
        f.close()

    mode = args.mode or MODE_DEFAULT

    if args.static:
        f = open(TMP_MODE, "r")
        mode = f.read().strip()
        f.close()
    else:
        f = open(TMP_MODE, "w")
        f.write(mode)
        f.close()

    if args.mode in ["next", "prev"]:
        mode = get_next_mode(mode) if args.mode == "next" else get_prev_mode(mode)

        f = open(TMP_MODE, "w")
        f.write(mode)
        f.close()

    content = get_content(mode)
    header = get_header(mode)

    if args.static:
        if args.static == "header":
            print(header)
        elif args.static == "content":
            print(content)
        return

    fuzzy_find(mode, content, header)


def args_parse():
    parser = argparse.ArgumentParser()

    parser.add_argument(
        "--static",
        type=str,
        default="",
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


def fuzzy_find(mode, content, header):
    subprocess.run(
        [
            "fzf",
            f"--listen={PORT}",
            "--ansi",
            "--header=" + header,
            f"--bind={KEY_MODE_NEXT}:"
            + f"execute-silent({SCRIPT_PATH} --static header --mode next)+reload({SCRIPT_PATH} --static content)+transform-header({SCRIPT_PATH} --static header)",
            f"--bind={KEY_MODE_PREV}:"
            + f"execute-silent({SCRIPT_PATH} --static header --mode prev)+reload({SCRIPT_PATH} --static content)+transform-header({SCRIPT_PATH} --static header)",
        ],
        input=content.encode(),
        text=False,
    )


def get_content(mode):
    if mode == "all":
        return "hello from all"
    elif mode == "session":
        return "hello from session"
    elif mode == "dir":
        return "hello from dir"
    else:
        raise ValueError(f"Unknown mode: {mode}")


def get_header(current_mode):
    header = f"Press {KEY_MODE_NEXT}/{KEY_MODE_PREV} to switch mode: "
    return f"{header}\n{get_header_modes(current_mode)}"


def get_next_mode(current_mode):
    return MODES[(MODES.index(current_mode) + 1) % len(MODES)]


def get_prev_mode(current_mode):
    return MODES[(MODES.index(current_mode) - 1) % len(MODES)]


def get_header_modes(current_mode):
    c_bold = subprocess.getoutput("tput bold")
    c_reset = subprocess.getoutput("tput sgr0")

    header_modes = []
    for mode in MODES:
        if mode == current_mode:
            header_modes.append(f"[{c_bold}{mode}{c_reset}]")
        else:
            header_modes.append(mode)

    return " ".join(header_modes)


if __name__ == "__main__":
    main()
