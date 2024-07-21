#!/usr/bin/env bash

###
# Launch a tmux session, window, or pane with a predefined starting directory
# and picked using a fuzzy finder (fzf).
###

INITIAL_DIR=""
MODE=""

# These directories will be listed as is
literalDirs=(
	"$HOME/.config"
	"$HOME/.local/share/nvim/lazy/LazyVim"
	"$HOME/Codes"
	"$HOME/Dotfiles"
	"$HOME/GoVault"
	"$HOME/Work"
)

# Direct child (one level deep) of this directories will be listed
childDirs=(
	"$HOME/.config"
	"$HOME/Codes"
	"$HOME/Dotfiles/packages"
	"$HOME/Work"
)

isInsideTmux() {
	[[ -n $TMUX ]] && return 0 || return 1
}

isTmuxServerRunning() {
	[[ -n $(pgrep tmux) ]] && return 0 || return 1
}

# Replaces '/home/username' to '~'
shrinkHome() {
	sed -E "s#^$HOME#~#"
}

# Replaces '~' to '/home/username'
expandHome() {
	sed -E "s#^~#$HOME#"
}

# If tmux is running, show it's pane start path
# else, show current dir
getCurrentDir() {
	# Skip if INITIAL_DIR is passed
	if [[ -n $INITIAL_DIR ]]; then
		return
	fi

	if [[ -n $TMUX ]]; then
		tmux display-message -p "#{pane_start_path}"
	else
		pwd
	fi

	printf "\n"
}

getLiteralDirs() {
	# Skip if array is empty
	if [[ ${#literalDirs} -lt 1 ]]; then
		return
	fi

	# Use `printf` to print the array
	printf "%s\n" "${literalDirs[@]}"

	printf "\n"
}

getChildDirs() {
	# Use `fd` to list down child dirs
	fd \
		--type=directory \
		--type=symlink \
		--max-depth=1 \
		--color=never \
		. "${childDirs[@]}"

	printf "\n"
}

getSessions() {
	if [[ -z $TMUX ]]; then
		return
	fi

	tmux list-session -F '#{session_name}|#{session_path}' |
		while read -r row; do
			session_name=$(echo "$row" | cut -d '|' -f 1)
			session_path=$(echo "$row" | cut -d '|' -f 2 | shrinkHome)

			_color_black=$(git config --get-color "" "black")
			_color_reset='\033[0m'

			echo -ne ">> "
			echo -ne "${session_path}"
			echo -ne "${_color_black}"
			echo -ne " :: "
			echo -ne "${session_name}"
			echo -ne "${_color_reset}"

			echo ""
		done |
		sort

	printf "\n"
}

isSession() {
	if [[ $1 =~ ^\>\>.* ]]; then
		return 0
	else
		return 1
	fi
}

getSessionName() {
	echo -n "$1" | awk -F " :: " '{print $2}'
}

getEntries() {
	(
		getSessions
		# getCurrentDir
		getLiteralDirs
		getChildDirs
	) | shrinkHome | uniq
}

fuzzyFind() {
	# Get header
	header="Select a directory for a new tmux pane/window/session"
	if [[ -n $INITIAL_DIR ]]; then
		header="Selecting from $INITIAL_DIR (ctrl-h to go back)"
	fi

	# use ctrl-l to go into highlighted directory
	# use ctrl-h to go back to parent directory
	fzf \
		--ansi \
		--header="$header" \
		--bind="ctrl-l:become($0 -initial-dir {})" \
		--bind="ctrl-h:become($0)"
}

getMode() {
	# Return preselected mode if exists
	if [[ -n $MODE ]]; then
		echo "$MODE"
		return
	fi

	# Select mode using fzf
	selected=$(echo -e "pane\nwindow\nsession" | fzf)
	if [[ -z $selected ]]; then
		echo "Mode is required"
	fi

	echo "$selected"
}

usage() {
	echo "Usage: $0 [-initial-dir <directory>] [-mode <pane|session|window>]"
	exit 1
}

main() {
	# Parse the command line arguments
	while [[ "$#" -gt 0 ]]; do
		case $1 in
		-initial-dir)
			if [[ -z $2 ]]; then
				echo "$1 required an argument"
				usage
			fi
			INITIAL_DIR="$2"
			shift 2
			;;
		-mode)
			if [[ -z $2 ]]; then
				echo "$1 required an argument"
				usage
			fi
			MODE="$2"
			shift 2
			;;
		*)
			echo "Unknown parameter passed: $1"
			usage
			;;
		esac
	done

	# Validate mode
	if [[ -n "$MODE" ]]; then
		if [[ "$MODE" != "pane" && "$MODE" != "window" && "$MODE" != "session" ]]; then
			echo "Invalid mode: $MODE. Allowed values are: pane, window, session."
			usage
		fi

	fi

	# If INITIAL_DIR is passed,
	# remove all predefined dirs and set initial dir to the selected one
	if [[ -n "$INITIAL_DIR" ]]; then
		newDir=$(echo "$INITIAL_DIR" | expandHome)
		childDirs=("$newDir")
		literalDirs=()
	fi

	# Select item
	selectedItem=$(getEntries | fuzzyFind)
	if [[ -z $selectedItem ]]; then
		exit 1
	fi

	# If item is a session entry, switch to them
	if isSession "$selectedItem"; then
		sessionName=$(getSessionName "$selectedItem")

		if [[ -z $TMUX ]]; then
			tmux attach-session -t "$sessionName"
		else
			tmux switch-client -t "$sessionName"
		fi

		exit 0
	fi

	# TODO:
	#  - add comments
	#  - determine to create pane/session/window
	#     - pane = tmux split-window -c
	#     - window = tmux new-window -c
	#     - session = tmux switch-client -c
	#  - refactor
	#     - main function for better readability
	#     - use isTmuxServerRunning and isInsideTmux
	#     - use consistent casing in getSessions

	# If item is a directory, get the mode (pane/window/session)
	# for the new item
	selectedMode=$(getMode)
	if [[ -z $selectedItem ]]; then
		exit 1
	fi

	targetSessionName=$(basename "$selectedItem" | tr . _)

	isTmuxRunning=$(pgrep tmux)
	if [[ -z $TMUX ]] && [[ -z $isTmuxRunning ]]; then
		tmux new-session -s "$targetSessionName" -c "$(echo "$selectedItem" | expandHome)"
		exit 0
	fi

	if ! tmux has-session -t "$targetSessionName" 2>/dev/null; then
		tmux new-session -ds "$targetSessionName" -c "$(echo "$selectedItem" | expandHome)"
	fi

	if [[ -z $TMUX ]]; then
		tmux attach-session -t "$targetSessionName"
	else
		tmux switch-client -t "$targetSessionName"
	fi
}

main "$@"
