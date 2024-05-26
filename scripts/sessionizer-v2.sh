#!/usr/bin/env bash

getChildDirs() {
	fd \
		--type=directory \
		--type=symlink \
		--max-depth=1 \
		. "${parent_dirs[@]}"
}

fuzzyFind() {
	fzf \
		--header="Select a directory for a new tmux session" \
		--preview="dir={}; exa -T ${dir/#\~/$HOME}" \
		--bind="ctrl-l:become($0 {})" \
		--bind="ctrl-h:become($0)" \
		--bind="ctrl-t:toggle-preview"
}

prependLine() {
	# echo "$1"
	# tmux display-message -p "#{pane_start_path}"
	cat
}

shrinkHome() {
	sed -E "s#^$HOME#~#"
}

expandHome() {
	sed -E "s#^~#$HOME#"
}

highlightExisting() {
	existing_sessions=("$(tmux list-sessions -F "#{session_path}" | sed -E "/[0-9]+$/d" | shrinkHome)")
	echo "${existing_sessions[@]}"
	echo '---'

	# while read -r line; do
	# 	for session in "${existing_sessions[@]}"; do
	#      echo "line: $line session: $session line: $line"
	# 		if [[ "$line" == "$session" ]]; then
	# 			break
	# 		fi
	# 	done
	#
	# 	printf "%s %s\n" "$line" ""
	# done

  cat 
}

parent_dirs=(
	# "$HOME/Codes"
	# "$HOME/Work"
	"$HOME/.config"
)

dirs=(
	"$HOME/Dotfiles"
)

if [[ $# -ge 1 ]]; then
	newDir=$(echo "$1" | expandHome)
	parent_dirs=("$newDir")
fi

selected=$(getChildDirs | prependLine "${dirs[@]}" | shrinkHome | highlightExisting | fuzzyFind)

if [[ -z $selected ]]; then
	exit 0
fi

selected_name=$(basename "$selected" | tr . _)

tmux_running=$(pgrep tmux)
if [[ -z $TMUX ]] && [[ -z $tmux_running ]]; then
	tmux new-session -s $selected_name -c $(echo $selected | expandHome)
	exit 0
fi

if ! tmux has-session -t $selected_name 2>/dev/null; then
	tmux new-session -ds $selected_name -c $(echo $selected | expandHome)
fi

if [[ -z $TMUX ]]; then
	tmux attach-session -t $selected_name
else
	tmux switch-client -t $selected_name
fi
