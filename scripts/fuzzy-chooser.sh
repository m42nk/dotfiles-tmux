#!/usr/bin/env bash

# https://ansi.gabebanks.net/

# fg bg style
# _c_sess=$(git config --get-color "" "black blue bold")
_c_sess=$(git config --get-color "" "blue bold")
_c_widx=$(git config --get-color "" "cyan bold")
_c_white=$(git config --get-color "" "default")
_c_default=$(git config --get-color "" "white")
_c_reset='\033[0m'
_c_underline='\x1b[4m'

current_session=$(tmux display -p '#{session_name}')
current_window=$(tmux display -p '#{window_index}')
current_pane=$(tmux display -p '#{pane_index}')

# tmux list-windows -a -F '#{session_name}|#{window_index}|#{window_name}|#{pane_current_command}' |
tmux list-panes -a -F '#{session_name}|#{window_index}|#{window_name}|#{pane_index}|#{pane_current_command}' |
	while read -r row; do
		session_name=$(echo "$row" | cut -d '|' -f 1)
		window_index=$(echo "$row" | cut -d '|' -f 2)
		window_name=$(echo "$row" | cut -d '|' -f 3)
		pane_index=$(echo "$row" | cut -d '|' -f 4)
		pane_command=$(echo "$row" | cut -d '|' -f 5)

		if [[ "$session_name" = "$current_session" ]] \
      && [[ "$window_index" = "$current_window" ]] \
      && [[ "$pane_index" = "$current_pane" ]]; then
      echo -ne "${_c_underline}"
		fi

		echo -ne "${_c_sess}${session_name}"
		echo -ne ":"
		echo -ne "${_c_widx}${window_index}"
		echo -ne "${_c_white} - ${window_name}"
		echo -ne "[${pane_command}]"
		echo -ne "${_c_reset}"

		# if [[ "$session_name" = "$current_session" ]] && [[ "$window_index" = "$current_window" ]]; then
		# 	echo -ne " <<"
		# fi

		echo ""
	done |
	fzf \
		--ansi \
    --header="Choose pane: " \
		--preview='tmux capture-pane -pe -t {1}' \
		--preview-window=right,70% \
		--bind 'ctrl-/:change-preview-window(hidden|)' |
	sed -E 's/ -.*//' |
	xargs -r tmux switch-client -t

    # --bind 'ctrl-r:reload(tmux capture-pane -pe -t {1})' |
# --preview='while true; do tmux capture-pane -pe -t {1}; clear; sleep 1; done' \
