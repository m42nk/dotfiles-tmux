#!/usr/bin/env bash

# https://ansi.gabebanks.net/

# fg bg style
# _c_sess=$(git config --get-color "" "black blue bold")
_c_sess=$(git config --get-color "" "blue bold")
_c_widx=$(git config --get-color "" "cyan bold")
_c_reset='\033[0m'

current_session=$(tmux display -p '#{session_name}')
current_window=$(tmux display -p '#{window_index}')

tmux list-windows -a -F '#{session_name}|#{window_index}|#{window_name}' |
	while read -r row; do
		session_name=$(echo "$row" | cut -d '|' -f 1)
		window_index=$(echo "$row" | cut -d '|' -f 2)
		window_name=$(echo "$row" | cut -d '|' -f 3)

		if [[ "$session_name" = "$current_session" ]] && [[ "$window_index" = "$current_window" ]]; then
			echo -ne "> "
		fi

		echo -ne "${_c_sess}${session_name}"
		echo -ne ":"
		echo -ne "${_c_widx}${window_index}"
		echo -ne "${_c_reset} - ${window_name}"

		echo ""
	done |
	fzf --ansi |
  sed -E 's/ -.*//'|
  xargs -r tmux switch-client -t
