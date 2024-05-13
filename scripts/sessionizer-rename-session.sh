#!/usr/bin/env bash

dirname=$(basename $(tmux display-message -p "#{pane_current_path}"))

tmux rename $dirname
tmux display-message "Session renamed to: $dirname"
