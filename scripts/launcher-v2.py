#!/usr/bin/env python3

import argparse
import subprocess
import os
import tempfile
import logging

"""
- User able to see the list of directories from config
- User able to select a directory and create new session
- User able to select a directory and attach to existing session if exists

- remove from dir list if session exists
- show active session first
- sort by last used (if possible, how?)
"""

# TODO: move to config
DIRS = {
    "$HOME/Work": {
        "depth": 1,
    },
    "$HOME/Codes": {
        "depth": 1,
    },
    "$HOME/Work/_projects/on-calls": {},
}

MODE_TYPE_ALL = "all"
MODE_TYPE_SESSION = "session"
MODE_TYPE_DIR = "dir"
MODE_TYPE_DEFAULT = MODE_TYPE_ALL
MODE_TYPES = [MODE_TYPE_ALL, MODE_TYPE_SESSION, MODE_TYPE_DIR]

MODE_TMP_FILE = os.path.join(tempfile.gettempdir(), "tmux-launcher-mode")

EXECUTABLE = os.path.realpath(__file__)

KEY_MODE_NEXT = "ctrl-n"
KEY_MODE_PREV = "ctrl-p"


LOG_FILE = os.path.join(tempfile.gettempdir(), "tmux-launcher.log")
logging.basicConfig(
    filename=LOG_FILE,
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)


def main():
    args = parse_args()
    mode = Mode.load()
    logging.info(f"Launcher started with mode: {mode.current}")

    if args.static:
        logging.info(f"Running static mode: {args.static}")
        print(f"internal mode: {args.static}")
        return

    # sample_input = "session|octopus|$HOME/Work/octopus|active\nsession|other|$HOME/Work/other|inactive\n"
    sess = Tmux.get_sessions()
    sample_input = [f"session|{s[0]}|{s[1]}|active" for s in sess]
    # TODO: metadata in separate column than display column, display column can be prettified
    output = fzf(prettify_columns(sample_input), header_build(mode))
    print(output)

    pass


def parse_args():
    parser = argparse.ArgumentParser(
        epilog=f"""
        Log file location:
        {LOG_FILE}
        """
    )

    parser.add_argument(
        "--static",
        type=str,
        choices=["header", "content", "next", "prev"],
        help="INTERNAL: output static content or change mode, used internally for FZF bindings",
    )

    parser.add_argument(
        "--mode",
        type=str,
        help="search mode",
        choices=MODE_TYPES,
    )

    return parser.parse_args()


def fzf(input: str, header: str = "") -> str:
    """
    echo "session|octopus|$HOME/Work/octopus|active" |
        fzf
        --delimiter "|" # used as nth delimiter
        --with-nth '{2}' # what to show in the list
        --nth 1 # what to search in (based on with-nth)
        --accept-nth '{1..3}' # what to output on accept
    """
    output = subprocess.run(
        [
            "fzf",
            "--ansi",
            "--no-sort",
        ],
        input=input,
        capture_output=True,
        text=True,
    )

    if output.returncode != 0:
        if output.returncode == 130:
            logging.info("FZF was cancelled by user (Ctrl-C)")
            return ""

        logging.error(f"FZF exited with code {output.returncode}")
        logging.error(f"FZF stderr: {output.stderr.strip()}")

    logging.info(f"FZF stdout: {output.stdout.strip()}")

    return output.stdout.strip()


class Mode:
    def __init__(self, mode):
        self.current = mode

    @classmethod
    def load(cls):
        if not os.path.exists(MODE_TMP_FILE):
            logging.info(
                f"Mode file not found, creating with default mode: {MODE_TYPE_DEFAULT}"
            )

            with open(MODE_TMP_FILE, "w") as f:
                f.write(MODE_TYPE_DEFAULT)

            return cls(MODE_TYPE_DEFAULT)

        with open(MODE_TMP_FILE, "r") as f:
            mode_type = f.read().strip()

        if mode_type not in MODE_TYPES:
            mode_type = MODE_TYPE_DEFAULT

        return cls(mode_type)

    def set(self, mode):
        if mode not in MODE_TYPES:
            logging.error(f"Attempted to set invalid mode: {mode}")
            raise ValueError(f"can't set an unknown mode: {mode}")

        logging.info(f"Setting mode from {self.current} to {mode}")
        self.current = mode
        self.save()

    def save(self):
        with open(MODE_TMP_FILE, "w") as f:
            f.write(self.current)

    def next(self):
        idx = MODE_TYPES.index(self.current)
        idx = (idx + 1) % len(MODE_TYPES)
        self.current = MODE_TYPES[idx]
        logging.info(f"Switched to next mode: {self.current}")
        self.save()

    def prev(self):
        idx = MODE_TYPES.index(self.current)
        idx = (idx - 1) % len(MODE_TYPES)
        self.current = MODE_TYPES[idx]
        logging.info(f"Switched to previous mode: {self.current}")
        self.save()


class Tmux:
    @staticmethod
    def is_running() -> bool:
        output = subprocess.run(
            ["tmux", "info"],
            capture_output=True,
            text=True,
        )
        return output.returncode == 0

    @staticmethod
    def get_sessions() -> list[tuple[str, str]]:
        if not Tmux.is_running():
            return []

        output = subprocess.run(
            ["tmux", "list-sessions", "-F", "#{session_name}|#{session_path}"],
            capture_output=True,
            text=True,
        )
        if output.returncode != 0:
            logging.error(f"Failed to list tmux sessions: {output.stderr.strip()}")
            return []

        raw_sessions = output.stdout.strip().split("\n")
        sessions = []
        for line in raw_sessions:
            if not line:
                continue

            parts = line.split("|")

            if len(parts) != 2:
                continue

            home_path = os.path.expanduser("~")
            parts[1] = parts[1].replace(home_path, "~")

            sessions.append((parts[0], parts[1]))

        return sessions


def prettify_columns(input: list[str] | str, separator: str = "|") -> str:
    if isinstance(input, list):
        input = "\n".join(input)

    output = subprocess.run(
        [
            "column",
            "-t",
            "-s",
            separator,
        ],
        input=input,
        capture_output=True,
        text=True,
    )

    if output.returncode != 0:
        logging.error(f"Failed to prettify columns: {output.stderr.strip()}")
        return input

    return output.stdout.strip()


def header_build(mode: Mode) -> str:
    header = f"Press {KEY_MODE_NEXT}/{KEY_MODE_PREV} to switch mode: "
    header_modes = header_modes_build(mode.current)
    return f"{header}\n{header_modes}"


def header_modes_build(current_mode):
    c_bold = subprocess.getoutput("tput bold")
    c_reset = subprocess.getoutput("tput sgr0")

    header_modes = []
    for mode in MODE_TYPES:
        if mode == current_mode:
            header_modes.append(f"[{c_bold}{mode}{c_reset}]")
        else:
            header_modes.append(mode)

    return " ".join(header_modes)


if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        logging.exception(f"Unhandled exception occurred: {e}")
        print(f"Error: {e}")
