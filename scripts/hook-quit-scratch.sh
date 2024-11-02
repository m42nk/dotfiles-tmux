#!/usr/bin/env bash

# TODO: not working
session_name=$(tmux display -p "#{session_name}")
terminal-notifier -message "Session $session_name has been closed" -title "tmux" -sound default
