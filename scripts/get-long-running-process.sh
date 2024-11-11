#!/usr/bin/env bash

CURR_SHELL=$(basename "$SHELL")
DEFAULT_SHELL="${CURR_SHELL:-zsh}"

# Loop through each pane in each tmux session and check the command being run
tmux list-panes -a -F "#{session_name}:#{window_index}.#{pane_index} #{pane_pid} #{pane_current_command}" |
  while read -r pane_info; do
    pane_cmd=$(echo "$pane_info" | awk '{print $3}')

    # Check if the command is not the default shell
    if [[ "$pane_cmd" != "$DEFAULT_SHELL" ]]; then
      echo "$pane_info"
    fi
  done
