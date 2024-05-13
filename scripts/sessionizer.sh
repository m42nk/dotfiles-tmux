#!/usr/bin/env bash

getDirs() {
	fd \
		--type=directory \
		--type=symlink \
		--max-depth=1 \
		. ${dirs[@]}
}

fuzzyFind() {
	fzf \
		--header="Select a directory for a new tmux session" \
		--preview='dir={}; exa -T ${dir/#\~/$HOME}' \
		--bind="ctrl-l:become($0 {})" \
		--bind="ctrl-h:become($0)"
}

appendCustomLine() {
	tmux display-message -p "#{pane_start_path}" && cat
}

shrinkHome() {
	sed -E "s#^$HOME#~#"
}

expandHome() {
	sed -E "s#^~#$HOME#"
}

dirs=(
	"$HOME/Codes"
	"$HOME/Work"
	"$HOME/.config"
	"$HOME/Dotfiles"
	"$HOME/Dotfiles/packages"
)

if [[ $# -ge 1 ]]; then
	newDir=$(echo "$1" | expandHome)
	dirs=("$newDir")
fi

# selected=$(getDirs | appendCustomLine | shrinkHome | fuzzyFind)
selected=$(getDirs | appendCustomLine | shrinkHome | fuzzyFind)

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
