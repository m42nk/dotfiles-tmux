#!/usr/bin/env bash

CURR_SHELL=$(basename "$SHELL")
DEFAULT_SHELL="${CURR_SHELL:-zsh}"

processes=()

# Loop through each pane in each tmux session and check the command being run
while read -r pane_info; do
  pane_cmd=$(echo "$pane_info" | awk '{print $3}')

  # Check if the command is not the default shell
  if [[ "$pane_cmd" != "$DEFAULT_SHELL" ]]; then
    processes+="$pane_info\n"
  fi
done < <(tmux list-panes -a -F "#{session_name}:#{window_index}.#{pane_index} #{pane_pid} #{pane_current_command}")

# Remove empty lines
processes=$(echo -e "${processes[@]}" | grep -v "^$")

# Remove current pane
processes=$(echo -e "${processes[@]}" | grep -v "$(tmux display -p '#{session_name}:#{window_index}.#{pane_index} #{pane_pid} #{pane_current_command}')")

if [[ -z "$processes" ]]; then
  echo "" | fzf --header="No long running processes found"
  exit 0
fi

# Run fzf to choose a process to kill (with confirmation) (with preview of tmux pane)
echo -e "${processes[@]}" | fzf --ansi --header="Choose process to kill: " --preview='tmux capture-pane -pe -t {1}' --preview-window=right,70% | awk '{print $1}' | xargs -r tmux kill-pane -t
